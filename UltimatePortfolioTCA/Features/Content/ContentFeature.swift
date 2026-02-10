import ComposableArchitecture
import SQLiteData
import SwiftUI

@Reducer struct ContentFeature {
    @ObservableState struct State {
        var filter: IssueFilter
        var selectedIssue: Issue?
        @FetchAll(Issue.none) var issues

        init(filter: IssueFilter) {
            self.filter = filter
            _issues = FetchAll(
                Issue
                    .order { ($0.priority.desc(nulls: .last), $0.modified.desc(nulls: .last), $0.created.desc()) }
                    .where {
                        switch filter {
                        case .all: true
                        case .completed: $0.completed
                        case .recent:
                            $0.created.gte(#sql("datetime('now', '-7 days', 'subsec')"))
                            || $0.modified.gte(#sql("datetime('now', '-7 days', 'subsec')"))
                        case let .tag(tag):
                            $0.id.in(
                                IssueTag.select(\.issueID).where { $0.tagID.eq(tag.id) }
                            )
                        }
                    },
                animation: .default
            )
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteIssuesSwiped(offsets: IndexSet)

        enum Delegate {
            case selectedIssueChanged
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case let .deleteIssuesSwiped(offsets):
                let ids = offsets.map { state.issues[$0].id }
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
                    if didDeleteSelectedIssue { await send(.delegate(.selectedIssueChanged)) }
                }
            }
        }
        BindingReducer()
    }
}
