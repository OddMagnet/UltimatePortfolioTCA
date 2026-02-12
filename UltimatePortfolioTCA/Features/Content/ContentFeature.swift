import ComposableArchitecture
import SQLiteData
import SwiftUI

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
        @Shared(.appStorage("issueSortOrder")) var sortOrder: IssueSortOrder = .priority
        @Shared(.appStorage("issueSortAscending")) var sortAscending = IssueSortOrder.priority.defaultAscending
        @FetchAll var issueRows: [IssueWithTags] = []

        init(filter: IssueFilter) {
            self.filter = filter
            _issueRows = FetchAll(issueQuery, animation: .default)
        }

        // Filter → Group → Sort → Join → Select
        var issueQuery: some Statement<IssueWithTags> {
            Issue
                .where {
                    switch filter {
                    case .open: true
                    case .completed: $0.isCompleted
                    case .recent: $0.isRecent
                    case let .tag(tag):
                        $0.id.in(
                            IssueTag.select(\.issueID).where { $0.tagID.eq(tag.id) }
                        )
                    }
                }
                .where {
                    if !showCompleted && filter != .completed {
                        !$0.isCompleted
                    }
                }
                .group(by: \.id)
                .order(by: \.isCompleted)
                .order {
                    switch (sortOrder, sortAscending) {
                    // TODO: extract $0.property.desc(...) into conveniences
                    case (.priority, false): $0.priority.desc(nulls: .last)
                    case (.priority, true): $0.priority.asc(nulls: .last)
                    case (.date, false): $0.lastActivity.desc()
                    case (.date, true): $0.lastActivity.asc()
                    case (.title, false): $0.title.desc()
                    case (.title, true): $0.title.asc()
                    }
                }
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
                if state.sortOrder == order {
                    state.$sortAscending.withLock { $0.toggle() }
                } else {
                    state.$sortAscending.withLock { $0 = order.defaultAscending }
                    state.$sortOrder.withLock { $0 = order }
                }
                return .send(.updateIssueRows)
            }
        }
    }
}
