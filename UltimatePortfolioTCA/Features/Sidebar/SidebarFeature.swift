import ComposableArchitecture
import Foundation
import SwiftUI
import SQLiteData

@Selection struct TagWithCount: Identifiable {
    var tag: Tag
    var activeIssueCount: Int
    var id: Tag.ID { tag.id }
}

@Selection struct SmartFilterCounts {
    var all = 0
    var completed = 0
    var recent = 0

    subscript(filter: IssueFilter) -> Int {
        switch filter {
        case .all: all
        case .completed: completed
        case .recent: recent
        case .tag: 0
        }
    }
}

@Reducer struct SidebarFeature {
    @ObservableState struct State {
        var selectedFilter: IssueFilter? = .all
        @FetchOne(
            Issue.select {
                SmartFilterCounts.Columns(
                    all: $0.count(),
                    completed: $0.count(filter: $0.isCompleted),
                    recent: $0.count(filter: $0.isRecent)
                )
            },
            animation: .default
        )
        var smartFilterCounts = SmartFilterCounts()
        // Group → Sort → Join → Select
        @FetchAll(
            Tag
                .group(by: \.id)
                .order(by: \.name)
                .leftJoin(IssueTag.all) { $0.id.eq($1.tagID) }
                .leftJoin(Issue.all) { $1.issueID.eq($2.id) }
                .select { tags, _, issues in
                    TagWithCount.Columns(
                        tag: tags,
                        activeIssueCount: issues.count(distinct: true, filter: issues.isCompleted.neq(true))
                    )
                },
            animation: .default
        ) var tagRows
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case view(View)

        enum Delegate {
            case selectedFilterChanged(IssueFilter?)
        }

        enum View {
            case deleteTagsSwiped(offsets: IndexSet)
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.selectedFilter):
                return .send(.delegate(.selectedFilterChanged(state.selectedFilter)))

            case .binding:
                return .none

            case .delegate:
                return .none

            case let .view(.deleteTagsSwiped(offsets)):
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
    }
}
