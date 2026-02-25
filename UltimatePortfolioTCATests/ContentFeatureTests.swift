import ComposableArchitecture
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    @MainActor struct ContentFeatureTests {
        let store: TestStoreOf<ContentFeature>

        init() {
            store = TestStore(initialState: ContentFeature.State(filter: .open)) {
                ContentFeature()
            }
        }

        // MARK: - State snapshots

        @Test func defaultContentStoreState() {
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                ContentFeature.State(
                  _filter: .open,
                  _selectedIssueID: nil,
                  _showCompleted: #1 false,
                  _sortOrder: #1 IssueSortOrder(
                    field: .priority,
                    isAscending: false
                  ),
                  _issueRows: [
                    [0]: IssueWithTags(
                      issue: Issue(
                        id: UUID(00000000-0000-0000-0000-00000000000A),
                        title: "Fix login screen layout",
                        detail: "The login button overlaps with the text field on smaller devices",
                        priority: .high,
                        isCompleted: false,
                        created: Date(2009-02-11T23:31:30.000Z),
                        modified: nil
                      ),
                      tagNames: "SwiftUI, Bug"
                    ),
                    [1]: IssueWithTags(
                      issue: Issue(
                        id: UUID(00000000-0000-0000-0000-00000000000B),
                        title: "Add dark mode support",
                        detail: "Implement dark mode across all screens using asset catalogs",
                        priority: .medium,
                        isCompleted: false,
                        created: Date(2009-01-30T23:31:30.000Z),
                        modified: Date(2009-02-10T23:31:30.000Z)
                      ),
                      tagNames: "SwiftUI, UI Design"
                    ),
                    [2]: IssueWithTags(
                      issue: Issue(
                        id: UUID(00000000-0000-0000-0000-00000000000D),
                        title: "Update onboarding flow",
                        detail: "Add new welcome screens with animations",
                        priority: .low,
                        isCompleted: false,
                        created: Date(2009-02-03T23:31:30.000Z),
                        modified: nil
                      ),
                      tagNames: "SwiftUI, UI Design"
                    )
                  ]
                )
                """
            }
        }

        // MARK: - Filters

        @Test func completedFilterShowsCompletedIssues() {
            let store = TestStore(initialState: ContentFeature.State(filter: .completed)) {
                ContentFeature()
            }
            assertInlineSnapshot(of: store.state.issueRows, as: .customDump) {
                """
                [
                  [0]: IssueWithTags(
                    issue: Issue(
                      id: UUID(00000000-0000-0000-0000-00000000000E),
                      title: "Fix crash on iPad rotation",
                      detail: "App crashes when rotating from portrait to landscape on iPad Pro",
                      priority: .high,
                      isCompleted: true,
                      created: Date(2009-01-23T23:31:30.000Z),
                      modified: Date(2009-02-12T23:31:30.000Z)
                    ),
                    tagNames: "SwiftUI, Bug"
                  ),
                  [1]: IssueWithTags(
                    issue: Issue(
                      id: UUID(00000000-0000-0000-0000-00000000000C),
                      title: "Refactor networking layer",
                      detail: "Replace URLSession calls with async/await",
                      priority: .medium,
                      isCompleted: true,
                      created: Date(2009-01-14T23:31:30.000Z),
                      modified: Date(2009-01-24T23:31:30.000Z)
                    ),
                    tagNames: "Networking"
                  )
                ]
                """
            }
        }

        @Test func openFilterIgnoresShowCompleted() async {
            // The open filter never shows completed issues regardless of the toggle
            let count = store.state.issueRows.count
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            await store.receive(\.issue​Query​Changed)
            await store.finish()
            #expect(store.state.issueRows.count == count)
        }

        @Test func tagFilterShowsIssuesForTag() {
            // NB: Uses the default showCompleted = false, so only open issues for this tag
            let testTag = Tag(id: UUID(5), name: "Bug")
            let store = TestStore(initialState: ContentFeature.State(filter: .tag(testTag))) {
                ContentFeature()
            }
            assertInlineSnapshot(of: store.state.issueRows, as: .customDump) {
                """
                [
                  [0]: IssueWithTags(
                    issue: Issue(
                      id: UUID(00000000-0000-0000-0000-00000000000A),
                      title: "Fix login screen layout",
                      detail: "The login button overlaps with the text field on smaller devices",
                      priority: .high,
                      isCompleted: false,
                      created: Date(2009-02-11T23:31:30.000Z),
                      modified: nil
                    ),
                    tagNames: "SwiftUI, Bug"
                  )
                ]
                """
            }
        }

        // MARK: - Selection

        @Test func selectedIssueChanged() async {
            #expect(store.state.selectedIssueID == nil)
            let selectedID = UUID(-1)
            await store.send(\.binding.selectedIssueID, selectedID) {
                $0.selectedIssueID = selectedID
            }
            await store.receive(\.delegate.selectedIssueChanged, selectedID)
            await store.send(\.binding.selectedIssueID, nil) {
                $0.selectedIssueID = nil
            }
            await store.receive(\.delegate.selectedIssueChanged, nil)
        }

        // MARK: - Sort order

        @Test func sortOrderSelected() async {
            #expect(store.state.sortOrder == IssueSortOrder(.priority))
            let sortOrder = IssueSortOrder(.title)
            // New sort order -> set default value
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0 = sortOrder }
            }
            await store.receive(\.issue​Query​Changed)
            await store.finish()
            let initialOrdering = store.state.issueRows.map(\.issue.title)
            // Same sort order -> change direction
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.receive(\.issue​Query​Changed)
            await store.finish()
            #expect(store.state.issueRows.map(\.issue.title) == initialOrdering.reversed())
        }

        // MARK: - Delete

        @Test func deleteIssuesSwipedOnUnselectedIssue() async throws {
            let unselectedIssueRow = try #require(store.state.issueRows.first)
            let unselectedIssueIndexSet: IndexSet = [0]
            await store.send(\.view.deleteIssuesSwiped, unselectedIssueIndexSet)
            await store.finish()
            #expect(!store.state.issueRows.contains(unselectedIssueRow))
        }

        @Test func deleteIssuesSwipedOnSelectedIssue() async throws {
            let selectedIssueRow = try #require(store.state.issueRows.first)
            let selectedIssueIndexSet: IndexSet = [0]
            await store.send(\.binding.selectedIssueID, selectedIssueRow.id) {
                $0.selectedIssueID = selectedIssueRow.id
            }
            await store.receive(\.delegate.selectedIssueChanged, selectedIssueRow.id)
            await store.send(\.view.deleteIssuesSwiped, selectedIssueIndexSet) {
                $0.selectedIssueID = nil
            }
            await store.receive(\.delegate.selectedIssueChanged, nil)
            #expect(!store.state.issueRows.contains(selectedIssueRow))
        }

        @Test func deleteIssuesSwipedOnMultipleIssues() async {
            #expect(!store.state.issueRows.isEmpty)
            let issueRowsIndexSet = IndexSet(integersIn: 0...store.state.issueRows.count - 1)
            await store.send(\.view.deleteIssuesSwiped, issueRowsIndexSet)
            await store.finish()
            #expect(store.state.issueRows.isEmpty)
        }

        @Test func deleteIssuesSwipedOnEmptyIndexSet() async {
            #expect(!store.state.issueRows.isEmpty)
            let issueRowsIndexSet = IndexSet()
            await store.send(\.view.deleteIssuesSwiped, issueRowsIndexSet)
            await store.finish()
            #expect(!store.state.issueRows.isEmpty)
        }

        // MARK: - Show completed

        @Test func showCompletedToggled() async {
            // Uses .recent filter since .open never shows completed issues
            let store = TestStore(initialState: ContentFeature.State(filter: .recent)) {
                ContentFeature()
            }
            #expect(!store.state.showCompleted)
            #expect(store.state.issueRows.count == 2)
            #expect(!store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
            // User toggles binding for showCompleted
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            // View reacts and sends the action
            await store.receive(\.issue​Query​Changed)
            await store.finish()
            #expect(store.state.issueRows.count == 3)
            #expect(store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
        }
    }
}
