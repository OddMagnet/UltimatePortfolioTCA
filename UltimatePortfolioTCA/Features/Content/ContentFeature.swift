import ComposableArchitecture
import SQLiteData
import SwiftUI

/// Query result combining an ``Issue`` with its comma-separated tag names from a grouped left join.
/// Produced by ``ContentFeature/State/issueQuery``.
@Selection struct IssueWithTags: Equatable, Identifiable {
    var issue: Issue
    var tagNames: String?
    var id: Issue.ID { issue.id }
}

@Reducer struct ContentFeature {
    @ObservableState struct State: Equatable {
        var filter: IssueFilter
        var selectedIssueID: Issue.ID?
        var searchText = ""
        var searchTokens: [SearchToken] = []
        var suggestedTokens: [SearchToken] = []
        @Shared(.appStorage(AppStorageKeys.showCompleted)) var showCompleted = false
        @Shared(.appStorage(AppStorageKeys.issueSortOrder)) var sortOrder = IssueSortOrder(.priority)
        @FetchAll var issueRows: [IssueWithTags] = []
        @FetchAll var availableTags: [Tag] = []

        /// Sets up the issue list observation (`@FetchAll`) for the given filter.
        init(filter: IssueFilter, selectedIssueID: Issue.ID? = nil) {
            self.filter = filter
            self.selectedIssueID = selectedIssueID
            _issueRows = FetchAll(issueQuery, animation: .default)
            _availableTags = FetchAll(Tag.order(by: \.name), animation: .default)
        }

        // MARK: - Search helpers

        /// Search text without tokens
        private var searchQuery: String {
            searchText
                .split(separator: " ", omittingEmptySubsequences: true)
                .filter { !$0.hasPrefix("#") }
                .joined(separator: " ")
        }

        /// Filters issues by the active filter, search text (FTS5), and search tokens,
        /// includes or excludes completed issues based on the filter's
        /// ``IssueFilter/showsCompletedIssues(with:)`` rule (overridden by status token),
        /// groups by issue ID, sorts by completion then user preference, joins with
        /// tags, and selects each issue with comma-separated tag names.
        /// Pipeline: Where → Group → Order → Join → Select
        var issueQuery: some Statement<IssueWithTags> {
            let sanitizedFTS = IssueText.sanitize(query: searchQuery)
            let tagTokenIDs = searchTokens.compactMap(\.tag?.id)
            let priorityToken = searchTokens.compactMap(\.priority).first
            let statusToken = searchTokens.compactMap(\.status).first

            return Issue
                .filter(with: filter)
                .where { // Completed-issue visibility
                    if statusToken == nil { // only filter when search does not have a status token
                        filter.showsCompletedIssues(with: showCompleted).or($0.isNotCompleted)
                    }
                }
                .where { // FTS5 full-text search
                    if let ftsQuery = sanitizedFTS {
                        // Search IssueText for matches, then get Issues based on their rowIDs
                        $0.rowid.in(IssueText.where { $0.match(ftsQuery) }.select { $0.rowid })
                    }
                }
                .where { // Priority token filter
                    if let priorityToken { $0.priority.eq(priorityToken) }
                }
                .where { // Status token filter
                    if let statusToken {
                        switch statusToken {
                        case .open: $0.isNotCompleted
                        case .completed: $0.isCompleted
                        }
                    }
                }
                .where { // Tag token filter (AND: must have all selected tags)
                    if !tagTokenIDs.isEmpty {
                        $0.id.in(
                            IssueTag
                                .where { $0.tagID.in(tagTokenIDs) } // Get IssueTags that have corrosponding tagIDs
                                .group(by: \.issueID) // group by issueID
                                .having { // if the count equals the tagTokenIDs count => Issue has all tags
                                    $0.tagID.count(distinct: true).eq(tagTokenIDs.count)
                                }
                                .select(\.issueID) // get the corrosponding IssueID
                        )
                    }
                }
                .group(by: \.id)
                .order(by: \.isCompleted)
                .order(by: sortOrder)
                .order(by: \.lastActivity)
                .leftJoin(IssueTag.all) { $0.id.eq($1.issueID) }
                .leftJoin(Tag.all) { $1.tagID.eq($2.id) }
                .select { issues, _, tags in
                    IssueWithTags.Columns(
                        issue: issues,
                        tagNames: tags.name.groupConcat(#sql("', '"))
                    )
                }
        }
    }

    enum CancelID: Hashable {
        case issueQuery
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case issueQueryChanged(debounce: Double?)
        case view(View)

        @CasePathable
        enum Delegate {
            case createIssue
            case selectedIssueChanged(Issue.ID?)
        }

        @CasePathable
        enum View {
            case createIssueButtonTapped
            case deleteIssuesSwiped(offsets: IndexSet)
            case sortOrderSelected(IssueSortOrder)
        }
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.selectedIssueID) { _, newID in
                Reduce<State, Action> { _, _ in .send(.delegate(.selectedIssueChanged(newID))) }
            }
            .onChange(of: \.showCompleted) { _, _ in
                Reduce<State, Action> { _, _ in .send(.issueQueryChanged(debounce: nil)) }
            }
            .onChange(of: \.searchText) { _, _ in
                Reduce<State, Action> { state, _ in
                    updateSuggestions(&state)
                    return .send(.issueQueryChanged(debounce: 0.3))
                }
            }
            .onChange(of: \.searchTokens) { _, _ in
                Reduce<State, Action> { state, _ in
                    updateSuggestions(&state)
                    return .send(.issueQueryChanged(debounce: 0.3))
                }
            }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .delegate:
                return .none

            case let .issueQueryChanged(debounceInSeconds):
                return .run { [state] _ in
                    if let debounceInSeconds {
                        try await clock.sleep(for: .seconds(debounceInSeconds))
                    }
                    try await state.$issueRows.load(state.issueQuery, animation: .default)
                }.cancellable(id: CancelID.issueQuery, cancelInFlight: true)

            case .view(.createIssueButtonTapped):
                return .send(.delegate(.createIssue))

            case let .view(.deleteIssuesSwiped(offsets)):
                let ids = offsets.map { state.issueRows[$0].issue.id }
                let didDeleteSelectedIssue = switch state.selectedIssueID {
                case let .some(selectedIssueID): ids.contains(selectedIssueID)
                default: false
                }
                if didDeleteSelectedIssue { state.selectedIssueID = nil }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.find(ids).delete().execute(db)
                        }
                    }
                    if didDeleteSelectedIssue { await send(.delegate(.selectedIssueChanged(nil))) }
                }

            case let .view(.sortOrderSelected(order)):
                state.$sortOrder.withLock { $0.apply(order) }
                return .send(.issueQueryChanged(debounce: nil))
            }
        }
    }

    private func updateSuggestions(_ state: inout State) {
        // 1. Make sure the last word is a token, if it isn't, reset suggested Tokens and return
        let words = state.searchText.split(separator: " ", omittingEmptySubsequences: false)
        guard let lastWord = words.last, lastWord.hasPrefix("#") else {
            state.suggestedTokens = []
            return
        }

        // 2. Remove the hashtag from it, make it lowercases.
        // Also create a set of the existing tokens id's to avoid showing duplicates
        let query = String(lastWord.dropFirst()).lowercased()
        let existingTokenIDs = Set(state.searchTokens.map(\.id))

        // 3. Create array for all possible suggestions
        let possibleSuggestions: [SearchToken] =
            state.availableTags.map(SearchToken.tag)
            + Issue.Priority.allCases.map(SearchToken.priority)
            + SearchToken.Status.allCases.map(SearchToken.status)

        // 4. Filter and set them to state's suggested tokens
        state.suggestedTokens = possibleSuggestions
            .filter { !existingTokenIDs.contains($0.id) }
            .filter { query.isEmpty || $0.label.lowercased().contains(query) }
    }
}
