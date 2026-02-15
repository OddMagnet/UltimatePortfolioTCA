import ComposableArchitecture
import SQLiteData
import SwiftUI

/// Query result combining an ``Issue`` with its comma-separated tag names from a grouped left join.
/// Produced by ``ContentFeature/State/issueQuery``.
@Selection struct IssueWithTags: Identifiable {
    var issue: Issue
    var tagNames: String?
    var id: Issue.ID { issue.id }
}

@Reducer struct ContentFeature {
    @ObservableState struct State {
        var filter: IssueFilter
        var selectedIssue: Issue?
        @Shared(.appStorage("showCompleted")) var showCompleted = false
        @Shared(.appStorage("issueSortOrder")) var sortOrder = IssueSortOrder(.priority)
        @FetchAll var issueRows: [IssueWithTags] = []

        /// Sets up the issue list observation (`@FetchAll`) for the given filter.
        init(filter: IssueFilter) {
            self.filter = filter
            _issueRows = FetchAll(issueQuery, animation: .default)
        }

        /// Filters issues by the active filter, hides completed (unless `showCompleted`
        /// or browsing the "Completed" smart filter), groups by issue ID, sorts by
        /// completion then user preference, joins with tags, and selects each issue
        /// with comma-separated tag names.
        /// Pipeline: Where → Group → Order → Join → Select
        var issueQuery: some Statement<IssueWithTags> {
            Issue
                .filter(with: filter)
                .where { (showCompleted || filter == .completed).or($0.isNotCompleted) }
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
        case updateIssueRows
        case view(View)

        enum Delegate {
            case selectedIssueChanged(Issue.ID?)
        }

        enum View {
            case deleteIssuesSwiped(offsets: IndexSet)
            case didSelectOrder(IssueSortOrder)
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.selectedIssue):
                return .send(.delegate(.selectedIssueChanged(state.selectedIssue?.id)))

            case .binding(\.showCompleted):
                return .send(.updateIssueRows)

            case .binding:
                return .none

            case .delegate:
                return .none

            case .updateIssueRows:
                return .run { [state] _ in
                    try await state.$issueRows.load(state.issueQuery, animation: .default)
                }

            case let .view(.deleteIssuesSwiped(offsets)):
                let ids = offsets.map { state.issueRows[$0].issue.id }
                let didDeleteSelectedIssue = switch(state.selectedIssue) {
                case let .some(selectedIssue): ids.contains(selectedIssue.id)
                default: false
                }
                if didDeleteSelectedIssue { state.selectedIssue = nil }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.find(ids).delete().execute(db)
                        }
                    }
                    if didDeleteSelectedIssue { await send(.delegate(.selectedIssueChanged(nil))) }
                }

            case let .view(.didSelectOrder(order)):
                if state.sortOrder.id == order.id {
                    state.$sortOrder.withLock { $0.toggle() }
                } else {
                    state.$sortOrder.withLock { $0 = order }
                }
                return .send(.updateIssueRows)
            }
        }
    }
}
