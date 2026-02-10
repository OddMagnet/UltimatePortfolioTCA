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
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
    }
}
