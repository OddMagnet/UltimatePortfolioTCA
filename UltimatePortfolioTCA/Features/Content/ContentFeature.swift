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
        @FetchAll var issueRows: [IssueWithTags] = []

        init(filter: IssueFilter) {
            self.filter = filter
            updateIssueQuery()
        }

        // Filter → Group → Sort → Join → Select
        mutating func updateIssueQuery() {
            _issueRows = FetchAll(
                Issue
                    .where {
                        switch filter {
                        case .all: true
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
                    .order { $0.priority.desc(nulls: .last) }
                    .order { $0.modified.desc(nulls: .last) }
                    .order { $0.created.desc() }
                    .leftJoin(IssueTag.all) { $0.id.eq($1.issueID) }
                    .leftJoin(Tag.all) { $1.tagID.eq($2.id) }
                    .select { issues, _, tags in
                        IssueWithTags.Columns(
                            issue: issues,
                            tagNames: tags.name.groupConcat(#sql("', '"))
                        )
                    },
                animation: .default
            )
        }
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case view(View)

        enum Delegate {
            case selectedIssueChanged(Issue.ID?)
        }

        enum View {
            case deleteIssuesSwiped(offsets: IndexSet)
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.selectedIssue):
                return .send(.delegate(.selectedIssueChanged(state.selectedIssue?.id)))

            case .binding(\.showCompleted):
                state.updateIssueQuery()
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none

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
            }
        }
    }
}
