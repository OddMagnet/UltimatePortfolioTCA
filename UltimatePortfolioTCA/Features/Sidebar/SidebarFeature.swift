import ComposableArchitecture
import Foundation
import SwiftUI
import SQLiteData

@Selection struct TagWithCount: Identifiable {
    var tag: Tag
    var issueCount: Int
    var id: Tag.ID { tag.id }
}

@Selection struct SmartFilterCounts {
    var open = 0
    var completed = 0
    var recent = 0

    subscript(filter: IssueFilter) -> Int {
        switch filter {
        case .open: open
        case .completed: completed
        case .recent: recent
        case .tag: 0
        }
    }
}

@Reducer struct SidebarFeature {
    @ObservableState struct State {
        var selectedFilter: IssueFilter? = .open
        @Shared(.appStorage("showCompleted")) var showCompleted = false
        @Shared(.appStorage("tagSortOrder")) var sortOrder: TagSortOrder = .name
        @Shared(.appStorage("tagSortAscending")) var sortAscending = TagSortOrder.name.defaultAscending
        @FetchOne var smartFilterCounts = SmartFilterCounts()
        @FetchAll var tagRows: [TagWithCount] = []

        init(selectedFilter: IssueFilter? = .open) {
            self.selectedFilter = selectedFilter
            _smartFilterCounts = FetchOne(wrappedValue: SmartFilterCounts(), smartFilterQuery, animation: .default)
            _tagRows = FetchAll(tagQuery, animation: .default)
        }

        var smartFilterQuery: some Statement<SmartFilterCounts> {
            Issue.select {
                SmartFilterCounts.Columns(
                    open: $0.count(filter: showCompleted.or(!$0.isCompleted)),
                    completed: $0.count(filter: $0.isCompleted),
                    recent: $0.count(filter: $0.isRecent.and(showCompleted.or(!$0.isCompleted)))
                )
            }
        }

        // Group → Join → Sort → Select
        var tagQuery: some Statement<TagWithCount> {
            Tag
                .group(by: \.id)
                .leftJoin(IssueTag.all) { $0.id.eq($1.tagID) }
                .leftJoin(Issue.all) { $1.issueID.eq($2.id) }
                .order { tags, _, issues in
                    switch (sortOrder, sortAscending) {
                    case (.name, true): tags.name.asc()
                    case (.name, false): tags.name.desc()
                    case (.issueCount, true):
                        issues.count(distinct: true, filter: showCompleted.or(issues.isCompleted.neq(true))).asc()
                    case (.issueCount, false):
                        issues.count(distinct: true, filter: showCompleted.or(issues.isCompleted.neq(true))).desc()
                    }
                }
                .order { tags, _, _ in tags.name }
                .select { tags, _, issues in
                    TagWithCount.Columns(
                        tag: tags,
                        issueCount: issues.count(distinct: true, filter: showCompleted.or(issues.isCompleted.neq(true)))
                    )
                }
        }
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
            case didSelectOrder(TagSortOrder)
            case showCompletedChanged
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
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
                if didDeleteSelectedFilter { state.selectedFilter = .open }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Tag.find(ids).delete().execute(db)
                        }
                    }
                    if didDeleteSelectedFilter { await send(.delegate(.selectedFilterChanged(nil))) }
                }

            case let .view(.didSelectOrder(order)):
                if state.sortOrder == order {
                    state.$sortAscending.withLock { $0.toggle() }
                } else {
                    state.$sortAscending.withLock { $0 = order.defaultAscending }
                    state.$sortOrder.withLock { $0 = order }
                }
                return .run { [state] _ in
                    try await state.$tagRows.load(state.tagQuery, animation: .default)
                }

            case .view(.showCompletedChanged):
                return .run { [state] _ in
                    _ = try await (
                        state.$smartFilterCounts.load(state.smartFilterQuery, animation: .default),
                        state.$tagRows.load(state.tagQuery, animation: .default)
                    )
                }
            }
        }
    }
}
