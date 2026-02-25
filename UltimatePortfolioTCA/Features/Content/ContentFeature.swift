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
        @Shared(.appStorage(AppStorageKeys.showCompleted)) var showCompleted = false
        @Shared(.appStorage(AppStorageKeys.issueSortOrder)) var sortOrder = IssueSortOrder(.priority)
        @FetchAll var issueRows: [IssueWithTags] = []

        /// Sets up the issue list observation (`@FetchAll`) for the given filter.
        init(filter: IssueFilter) {
            self.filter = filter
            _issueRows = FetchAll(issueQuery, animation: .default)
        }

        /// Filters issues by the active filter, includes or excludes completed issues
        /// based on the filter's ``IssueFilter/showsCompletedIssues(with:)`` rule,
        /// groups by issue ID, sorts by completion then user preference, joins with
        /// tags, and selects each issue with comma-separated tag names.
        /// Pipeline: Where → Group → Order → Join → Select
        var issueQuery: some Statement<IssueWithTags> {
            Issue
                .filter(with: filter)
                .where { filter.showsCompletedIssues(with: showCompleted).or($0.isNotCompleted) }
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

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case issue​Query​Changed
        case view(View)

        @CasePathable
        enum Delegate {
            case selectedIssueChanged(Issue.ID?)
        }

        @CasePathable
        enum View {
            case deleteIssuesSwiped(offsets: IndexSet)
            case sortOrderSelected(IssueSortOrder)
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.selectedIssueID):
                return .send(.delegate(.selectedIssueChanged(state.selectedIssueID)))

            case .binding(\.showCompleted):
                return .send(.issue​Query​Changed)

            case .binding:
                return .none

            case .delegate:
                return .none

            case .issue​Query​Changed:
                return .run { [state] _ in
                    try await state.$issueRows.load(state.issueQuery, animation: .default)
                }

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
                return .send(.issue​Query​Changed)
            }
        }
    }
}
