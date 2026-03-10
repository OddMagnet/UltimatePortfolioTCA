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
            store = TestStore(initialState: SidebarFeature.State(selectedFilter: .open)) {
                SidebarFeature()
            }
        }

        // MARK: - State snapshots

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
                    open: 5,
                    completed: 2,
                    recent: 4
                  ),
                  _tagRows: [
                    [0]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000006),
                        name: "Accessibility & VoiceOver"
                      ),
                      issueCount: 1
                    ),
                    [1]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000005),
                        name: "Bug"
                      ),
                      issueCount: 1
                    ),
                    [2]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000003),
                        name: "Core Data"
                      ),
                      issueCount: 0
                    ),
                    [3]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000002),
                        name: "Networking"
                      ),
                      issueCount: 1
                    ),
                    [4]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000001),
                        name: "SwiftUI"
                      ),
                      issueCount: 4
                    ),
                    [5]: TagWithCount(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000004),
                        name: "UI Design"
                      ),
                      issueCount: 3
                    )
                  ]
                )
                """
            }
        }

        // MARK: - Bindings

        @Test func selectedFilterBinding() async {
            await store.send(\.binding.selectedFilter, .completed) {
                $0.selectedFilter = .completed
            }
            await store.receive(\.delegate.selectedFilterChanged, .completed)
            await store.send(\.binding.selectedFilter, nil) {
                $0.selectedFilter = nil
            }
            await store.receive(\.delegate.selectedFilterChanged, nil)
            await store.send(\.binding.selectedFilter, .tag(testTag)) {
                $0.selectedFilter = .tag(testTag)
            }
            await store.receive(\.delegate.selectedFilterChanged, .tag(testTag))
        }

        // MARK: - Selection

        @Test func selectedFilterBindingSendsDelegateAction() async {
            await store.send(\.binding.selectedFilter, .tag(testTag)) {
                $0.selectedFilter = .tag(testTag)
            }
            await store.receive(\.delegate.selectedFilterChanged, .tag(testTag))
        }

        // MARK: - Tag management

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
            await store.send(\.view.deleteTagsSwiped, [unselectedTag.id])
            await store.finish()
            #expect(!store.state.tagRows.contains(unselectedTagRow))
        }

        @Test func deleteTagSwipedOnSelectedFilter() async throws {
            // Deleting the tag backing the current filter resets selection to .open
            let selectedTagRow = try #require(store.state.tagRows.first)
            let selectedTag = selectedTagRow.tag
            await store.send(\.binding.selectedFilter, .tag(selectedTag)) {
                $0.selectedFilter = .tag(selectedTag)
            }
            await store.receive(\.delegate.selectedFilterChanged, .tag(selectedTag))
            await store.send(\.view.deleteTagsSwiped, [selectedTag.id]) {
                $0.selectedFilter = .open
            }
            await store.receive(\.delegate.selectedFilterChanged, .open)
            await store.finish()
            #expect(!store.state.tagRows.contains(selectedTagRow))
        }

        // MARK: - Sort order

        @Test func sortOrderSelected() async {
            #expect(store.state.sortOrder == TagSortOrder(.name))
            let sortOrder = TagSortOrder(.issueCount)
            // New sort order -> set default value
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.finish()
            #expect(store.state.tagRows.first?.issueCount == 4)
            #expect(store.state.tagRows.last?.issueCount == 0)
            // Same sort order -> change direction
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.finish()
            #expect(store.state.tagRows.first?.issueCount == 0)
            #expect(store.state.tagRows.last?.issueCount == 4)
        }

        // MARK: - Show completed

        @Test func showCompletedToggled() async {
            #expect(!store.state.showCompleted)
            #expect(store.state.smartFilterCounts == SmartFilterCounts(open: 5, completed: 2, recent: 4))
            #expect(store.state.tagRows.map(\.issueCount) == [1, 1, 0, 1, 4, 3])
            // User toggles binding for showCompleted
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            // View reacts and sends the action
            await store.send(\.view.showCompletedToggled)
            await store.finish()
            #expect(store.state.smartFilterCounts == SmartFilterCounts(open: 5, completed: 2, recent: 5))
            #expect(store.state.tagRows.map(\.issueCount) == [1, 2, 0, 2, 5, 3])
        }

        // MARK: - Show Awards

        @Test func showAwardsButtonTapped() async {
            await store.send(\.view.showAwardsButtonTapped)
            await store.receive(\.delegate.showAwards)
        }
    }
}
