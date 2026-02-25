import ComposableArchitecture
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    @MainActor struct SidebarFeatureTests {
        let store: TestStoreOf<SidebarFeature>
        let testTag = Tag(id: UUID(-1), name: "Test")

        init() {
            store = TestStore(initialState: SidebarFeature.State()) {
                SidebarFeature()
            }
        }

        @Test func defaultSidebarStoreState() {
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                SidebarFeature.State(
                  _selectedFilter: .open,
                  _showCompleted: #1 false,
                  _sortOrder: #1 TagSortOrder(
                    field: .name,
                    isAscending: true
                  ),
                  _smartFilterCounts: SmartFilterCounts(
                    open: 3,
                    completed: 2,
                    recent: 2
                  ),
                  _tagRows: [
                    [0]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000005),
                        name: "Bug"
                      ),
                      issueCount: 1
                    ),
                    [1]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000003),
                        name: "Core Data"
                      ),
                      issueCount: 0
                    ),
                    [2]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000002),
                        name: "Networking"
                      ),
                      issueCount: 0
                    ),
                    [3]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000001),
                        name: "SwiftUI"
                      ),
                      issueCount: 3
                    ),
                    [4]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000004),
                        name: "UI Design"
                      ),
                      issueCount: 2
                    )
                  ]
                )
                """
            }
        }

        @Test func updateSelectedFilter() async {
            await store.send(\.updateSelectedFilter, .tag(testTag)) {
                $0.selectedFilter = .tag(testTag)
            }
        }

        @Test func createTagButtonTapped() async {
            await store.send(\.view.createTagButtonTapped)
            await store.receive(\.delegate.createTag, UUID(0))
        }

        @Test func renameTagSwiped() async {
            await store.send(\.view.renameTagSwiped, testTag)
            await store.receive(\.delegate.renameTag, testTag)
        }

        @Test func deleteTagSwipedOnUnselectedFilter() async throws {
            let unselectedTagRow = try #require(store.state.tagRows.first)
            let unselectedTag = unselectedTagRow.tag
            await store.send(\.view.deleteTagSwiped, unselectedTag)
            await store.finish()
            #expect(!store.state.tagRows.contains(unselectedTagRow))
        }

        @Test func deleteTagSwipedOnSelectedFilter() async throws {
            let selectedTagRow = try #require(store.state.tagRows.first)
            let selectedTag = selectedTagRow.tag
            await store.send(\.updateSelectedFilter, .tag(selectedTag)) {
                $0.selectedFilter = .tag(selectedTag)
            }
            await store.send(\.view.deleteTagSwiped, selectedTag) {
                $0.selectedFilter = .open
            }
            await store.receive(\.delegate.selectedFilterChanged, .open)
            #expect(!store.state.tagRows.contains(selectedTagRow))
        }

        @Test func sortOrderSelected() async {
            #expect(store.state.sortOrder == TagSortOrder(.name))
            let sortOrder = TagSortOrder(.issueCount)
            // New sort order -> set default value
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0 = TagSortOrder(.issueCount) }
            }
            await store.finish()
            // Same sort order -> change direction
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.finish()
        }

        @Test func showCompletedToggled() async {
            #expect(!store.state.showCompleted)
            #expect(store.state.smartFilterCounts == SmartFilterCounts(open: 3, completed: 2, recent: 2))
            #expect(store.state.tagRows.map(\.issueCount) == [1, 0, 0, 3, 2])
            // User toggles binding for showCompleted
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            // View reacts and sends the action
            await store.send(\.view.showCompletedToggled)
            await store.finish()
            #expect(store.state.smartFilterCounts == SmartFilterCounts(open: 3, completed: 2, recent: 3))
            #expect(store.state.tagRows.map(\.issueCount) == [2, 0, 1, 4, 2])
        }
    }
}
