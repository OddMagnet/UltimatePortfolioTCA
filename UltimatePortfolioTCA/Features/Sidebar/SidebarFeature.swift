import ComposableArchitecture
import Foundation
import SQLiteData
import SwiftUI

/// Query result combining a ``Tag`` with the count of its visible (non-completed, unless `showCompleted`) issues.
/// Produced by ``SidebarFeature/State/tagQuery`` via a grouped left join through ``IssueTag``.
@Selection struct TagWithCount: Equatable, Identifiable {
    var tag: Tag
    var issueCount: Int
    var id: Tag.ID { tag.id }
}

/// Aggregated issue counts for the three smart filters (Open, Completed, Recent).
/// The subscript provides type-safe access by ``IssueFilter``; `.tag` always returns 0.
@Selection struct SmartFilterCounts: Equatable {
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
    @ObservableState struct State: Equatable {
        var selectedFilter: IssueFilter?
        @Shared(.appStorage(AppStorageKeys.showCompleted)) var showCompleted = false
        @Shared(.appStorage(AppStorageKeys.tagSortOrder)) var sortOrder = TagSortOrder(.name)
        @FetchOne var smartFilterCounts = SmartFilterCounts()
        @FetchAll var tagRows: [TagWithCount] = []

        /// Sets up database observations for smart filter counts (`@FetchOne`) and tag rows (`@FetchAll`).
        init(selectedFilter: IssueFilter? = .open) {
            self.selectedFilter = selectedFilter
            _smartFilterCounts = FetchOne(wrappedValue: SmartFilterCounts(), smartFilterQuery, animation: .default)
            _tagRows = FetchAll(tagQuery, animation: .default)
        }

        /// Counts issues per smart filter.
        /// Open always excludes completed issues. Recent excludes them unless `showCompleted` is true.
        /// Pipeline: Select (aggregate)
        var smartFilterQuery: some Statement<SmartFilterCounts> {
            Issue.select {
                SmartFilterCounts.Columns(
                    open: $0.count(filter: $0.isNotCompleted),
                    completed: $0.count(filter: $0.isCompleted),
                    recent: $0.count(filter: $0.isRecent.and(showCompleted.or($0.isNotCompleted)))
                )
            }
        }

        /// Groups tags by ID, joins through ``IssueTag`` to ``Issue``, sorts by user preference,
        /// and selects each tag with its visible issue count. Uses `leftJoin` so tags with no
        /// issues still appear. Secondary sort by name ensures stable ordering.
        /// Pipeline: Group → Join → Order → Select
        var tagQuery: some Statement<TagWithCount> {
            Tag
                .group(by: \.id)
                .leftJoin(IssueTag.all) { $0.id.eq($1.tagID) }
                .leftJoin(Issue.all) { $1.issueID.eq($2.id) }
                .order(by: sortOrder, showCompleted: showCompleted)
                .order { tags, _, _ in tags.name }
                .select { tags, _, issues in
                    let isVisible = showCompleted.or(issues.isCompleted.neq(true))
                    return TagWithCount.Columns(
                        tag: tags,
                        issueCount: issues.count(distinct: true, filter: isVisible)
                    )
                }
        }
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case view(View)

        @CasePathable
        enum Delegate {
            case createTag(Tag.ID)
            case renameTag(Tag)
            case selectedFilterChanged(IssueFilter?)
            case showAwards
        }

        @CasePathable
        enum View {
            case createTagButtonTapped
            case deleteTagsSwiped([Tag.ID])
            case renameTagSwiped(Tag)
            case sortOrderSelected(TagSortOrder)
            case showAwardsButtonTapped
            case showCompletedToggled
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.selectedFilter) { _, newValue in
                Reduce<State, Action> { _, _ in
                    .send(.delegate(.selectedFilterChanged(newValue)))
                }
            }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .delegate:
                return .none

            case .view(.createTagButtonTapped):
                return .send(.delegate(.createTag(uuid())))

            case let .view(.renameTagSwiped(tag)):
                return .send(.delegate(.renameTag(tag)))

            case let .view(.deleteTagsSwiped(tagIDs)):
                let didDeleteSelectedFilter = switch state.selectedFilter {
                case let .tag(selectedTag): tagIDs.contains(selectedTag.id)
                default: false
                }
                if didDeleteSelectedFilter {
                    state.selectedFilter = .open
                }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Tag.where { $0.id.in(tagIDs) }.delete().execute(db)
                        }
                    }
                    if didDeleteSelectedFilter {
                        await send(.delegate(.selectedFilterChanged(.open)))
                    }
                }

            case let .view(.sortOrderSelected(order)):
                state.$sortOrder.withLock { $0.apply(order) }
                return .run { [state] _ in
                    try await state.$tagRows.load(state.tagQuery, animation: .default)
                }

            case .view(.showAwardsButtonTapped):
                return .send(.delegate(.showAwards))

            case .view(.showCompletedToggled):
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
