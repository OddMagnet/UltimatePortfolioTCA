import ComposableArchitecture
import Foundation
import SQLiteData

@Selection struct TagWithCount: Identifiable {
    var tag: Tag
    var activeIssueCount: Int
    var id: Tag.ID { tag.id }
}

@Reducer struct SidebarFeature {
    @ObservableState struct State {
        var selectedFilter: IssueFilter? = .all
        @Fetch(IssueFilter.smartFilterCounts) var smartFilterCounts = .init()
        @FetchAll(
            Tag
                .group(by: \.id)
                .order(by: \.name)
                .leftJoin(IssueTag.all) { $0.id.eq($1.tagID) }
                .leftJoin(Issue.all) { $1.issueID.eq($2.id) }
                .select { tags, _, issues in
                    TagWithCount.Columns(
                        tag: tags,
                        activeIssueCount: issues.count(distinct: true, filter: issues.completed.neq(true))
                    )
                }
        ) var tagRows
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case deleteTagsSwiped(offsets: IndexSet)

        enum Delegate {
            case selectedFilterChanged(IssueFilter?)
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .binding(\.selectedFilter):
                return .send(.delegate(.selectedFilterChanged(state.selectedFilter)))

            case .binding:
                return .none

            case .delegate:
                return .none

            case let .deleteTagsSwiped(offsets):
                let ids = offsets.map { state.tagRows[$0].tag.id }
                let didDeleteSelectedFilter = switch(state.selectedFilter) {
                case let .tag(tag): ids.contains(tag.id)
                default: false
                }
                if didDeleteSelectedFilter { state.selectedFilter = .all }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Tag.find(ids).delete().execute(db)
                        }
                    }
                    if didDeleteSelectedFilter { await send(.delegate(.selectedFilterChanged(nil))) }
                }
            }
        }
        BindingReducer()
    }
}
