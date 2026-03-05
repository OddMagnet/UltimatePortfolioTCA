import ComposableArchitecture
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import Testing
@testable import UltimatePortfolioTCA

// swiftlint:disable file_length
extension BaseTestSuite {
    // swiftlint:disable:next type_body_length
    @MainActor struct ContentFeatureTests {
        let store: TestStoreOf<ContentFeature>

        init() {
            store = TestStore(initialState: ContentFeature.State(filter: .open)) {
                ContentFeature()
            }
        }

        // MARK: - State snapshots

        // swiftlint:disable:next function_body_length
        @Test func defaultContentStoreState() {
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                ContentFeature.State(
                  _filter: .open,
                  _selectedIssueID: nil,
                  _searchText: "",
                  _searchTokens: [],
                  _suggestedTokens: [],
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
                        id: UUID(00000000-0000-0000-0000-000000000010),
                        title: "Implement comprehensive push notification system with background delivery and rich media attachments",
                        detail: "We need a full push notification system that handles foreground, background, and terminated states. This should include support for rich media attachments (images, video thumbnails), notification actions (reply, mark as read, snooze), and a notification service extension for decrypting end-to-end encrypted payloads. The system should also integrate with the existing badge count logic and group notifications by conversation thread using the thread-id field.",
                        priority: .medium,
                        isCompleted: false,
                        created: Date(2009-02-05T23:31:30.000Z),
                        modified: Date(2009-02-09T23:31:30.000Z)
                      ),
                      tagNames: "SwiftUI, Networking, UI Design, Accessibility & VoiceOver"
                    ),
                    [2]: IssueWithTags(
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
                    [3]: IssueWithTags(
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
                    ),
                    [4]: IssueWithTags(
                      issue: Issue(
                        id: UUID(00000000-0000-0000-0000-00000000000F),
                        title: "Audit VoiceOver labels and traits across the entire application for WCAG 2.1 AA compliance",
                        detail: "",
                        priority: .low,
                        isCompleted: false,
                        created: Date(2009-02-08T23:31:30.000Z),
                        modified: nil
                      ),
                      tagNames: nil
                    )
                  ],
                  _availableTags: [
                    [0]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000006),
                      name: "Accessibility & VoiceOver"
                    ),
                    [1]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000005),
                      name: "Bug"
                    ),
                    [2]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000003),
                      name: "Core Data"
                    ),
                    [3]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000002),
                      name: "Networking"
                    ),
                    [4]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000001),
                      name: "SwiftUI"
                    ),
                    [5]: Tag(
                      id: UUID(00000000-0000-0000-0000-000000000004),
                      name: "UI Design"
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
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == count)
        }

        @Test func recentFilterShowOnlyRecentIssues() {
            // The recent filter never shows issues > 1 week
            // based on dependency date in BaseTestSuite
            // => GMT: Friday, 13 February 2009 at 23:31:30
            let store = TestStore(initialState: ContentFeature.State(filter: .recent)) {
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
                  ),
                  [1]: IssueWithTags(
                    issue: Issue(
                      id: UUID(00000000-0000-0000-0000-000000000010),
                      title: "Implement comprehensive push notification system with background delivery and rich media attachments",
                      detail: "We need a full push notification system that handles foreground, background, and terminated states. This should include support for rich media attachments (images, video thumbnails), notification actions (reply, mark as read, snooze), and a notification service extension for decrypting end-to-end encrypted payloads. The system should also integrate with the existing badge count logic and group notifications by conversation thread using the thread-id field.",
                      priority: .medium,
                      isCompleted: false,
                      created: Date(2009-02-05T23:31:30.000Z),
                      modified: Date(2009-02-09T23:31:30.000Z)
                    ),
                    tagNames: "SwiftUI, Networking, UI Design, Accessibility & VoiceOver"
                  ),
                  [2]: IssueWithTags(
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
                  [3]: IssueWithTags(
                    issue: Issue(
                      id: UUID(00000000-0000-0000-0000-00000000000F),
                      title: "Audit VoiceOver labels and traits across the entire application for WCAG 2.1 AA compliance",
                      detail: "",
                      priority: .low,
                      isCompleted: false,
                      created: Date(2009-02-08T23:31:30.000Z),
                      modified: nil
                    ),
                    tagNames: nil
                  )
                ]
                """
            }
        }

        @Test func tagFilterShowsIssuesForTag() {
            // NB: Uses the default showCompleted = false, so only open issues for this tag
            let testTag = Tag(id: .tagBug, name: "Bug")
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

        @Test func sortOrderTitleSelected() async {
            #expect(store.state.sortOrder == IssueSortOrder(.priority))
            let sortOrder = IssueSortOrder(.title)
            // New sort order -> set default value
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0 = sortOrder }
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            let initialOrdering = store.state.issueRows.map(\.issue.title)
            // Same sort order -> change direction
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.map(\.issue.title) == initialOrdering.reversed())
        }

        @Test func sortOrderDateSelected() async {
            #expect(store.state.sortOrder == IssueSortOrder(.priority))
            let sortOrder = IssueSortOrder(.date)
            // New sort order -> set default value
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0 = sortOrder }
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            let initialOrdering = store.state.issueRows.map(\.issue.title)
            // Same sort order -> change direction
            await store.send(\.view.sortOrderSelected, sortOrder) {
                $0.$sortOrder.withLock { $0.apply(sortOrder) }
            }
            await store.receive(\.issueQueryChanged)
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
            #expect(store.state.issueRows.count == 4)
            #expect(!store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
            // User toggles binding for showCompleted
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            // View reacts and sends the action
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 5)
            #expect(store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
        }

        @Test func showCompletedToggledForTagsFilter() async {
            let tag = Tag(id: .tagSwiftUI, name: "SwiftUI")
            let store = TestStore(initialState: ContentFeature.State(filter: .tag(tag))) {
                ContentFeature()
            }
            #expect(!store.state.showCompleted)
            #expect(store.state.issueRows.count == 4)
            #expect(!store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
            // User toggles binding for showCompleted
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            // View reacts and sends the action
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 5)
            #expect(store.state.issueRows.contains(where: { $0.issue.title == "Fix crash on iPad rotation" }))
        }

        // MARK: - Search text (FTS5)

        @Test func searchTextMatchesTitle() async {
            await store.send(\.binding.searchText, "login") {
                $0.searchText = "login"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Fix login screen layout")
        }

        @Test func searchTextMatchesDetail() async {
            await store.send(\.binding.searchText, "overlaps") {
                $0.searchText = "overlaps"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Fix login screen layout")
        }

        @Test func searchTextNoMatch() async {
            await store.send(\.binding.searchText, "zzzznonexistent") {
                $0.searchText = "zzzznonexistent"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.isEmpty)
        }

        @Test func searchTextPrefixMatches() async {
            // FTS5 prefix matching: "dark" should match "dark mode support"
            await store.send(\.binding.searchText, "dark") {
                $0.searchText = "dark"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Add dark mode support")
        }

        @Test func clearSearchRestoresFullList() async {
            let originalCount = store.state.issueRows.count
            await store.send(\.binding.searchText, "login") {
                $0.searchText = "login"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == 1)
            // Clear search
            await store.send(\.binding.searchText, "") {
                $0.searchText = ""
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count == originalCount)
        }

        // MARK: - Priority token

        @Test func priorityTokenFiltersHighOnly() async {
            let token = SearchToken.priority(.high)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.allSatisfy { $0.issue.priority == .high })
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Fix login screen layout")
        }

        @Test func priorityTokenFiltersMedium() async {
            let token = SearchToken.priority(.medium)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.allSatisfy { $0.issue.priority == .medium })
            #expect(store.state.issueRows.count == 2)
        }

        // MARK: - Status token

        @Test func statusTokenCompletedShowsCompleted() async {
            // Status token overrides the filter's completed-issue visibility
            let token = SearchToken.status(.completed)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.filter(\.issue.isCompleted).count == store.state.issueRows.count)
            #expect(store.state.issueRows.count == 2)
        }

        @Test func statusTokenOpenShowsOpenOnly() async {
            // Use .recent filter with showCompleted=true, then apply .open token
            let store = TestStore(initialState: ContentFeature.State(filter: .recent)) {
                ContentFeature()
            }
            // First enable show completed so we have both open and completed
            await store.send(\.binding.showCompleted, true) {
                $0.$showCompleted.withLock { $0 = true }
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            let countWithCompleted = store.state.issueRows.count
            #expect(store.state.issueRows.contains { $0.issue.isCompleted })
            // Apply open status token — should override and show only open
            let token = SearchToken.status(.open)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.allSatisfy { !$0.issue.isCompleted })
            #expect(store.state.issueRows.count < countWithCompleted)
        }

        // MARK: - Tag token

        @Test func tagTokenFiltersByTag() async {
            let bugTag = Tag(id: .tagBug, name: "Bug")
            let token = SearchToken.tag(bugTag)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            // Only open issues tagged "Bug": "Fix login screen layout"
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Fix login screen layout")
        }

        // MARK: - Multiple tokens (AND)

        @Test func multipleTokensCombineWithAND() async {
            // SwiftUI tag + medium priority = only medium-priority SwiftUI-tagged open issues
            let swiftUITag = Tag(id: .tagSwiftUI, name: "SwiftUI")
            let tokens: [SearchToken] = [.tag(swiftUITag), .priority(.medium)]
            await store.send(\.binding.searchTokens, tokens) {
                $0.searchTokens = tokens
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.allSatisfy { $0.issue.priority == .medium })
            // Should include "Add dark mode support" and "Implement comprehensive push..."
            #expect(store.state.issueRows.count == 2)
        }

        // MARK: - Text + tokens combined

        @Test func searchTextWithTagToken() async {
            let swiftUITag = Tag(id: .tagSwiftUI, name: "SwiftUI")
            let token = SearchToken.tag(swiftUITag)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            let countWithTag = store.state.issueRows.count
            // Now also search for "dark"
            await store.send(\.binding.searchText, "dark") {
                $0.searchText = "dark"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.issueRows.count < countWithTag)
            #expect(store.state.issueRows.count == 1)
            #expect(store.state.issueRows.first?.issue.title == "Add dark mode support")
        }

        // MARK: - Suggestions

        @Test func suggestionsAppearOnHash() async {
            await store.send(\.binding.searchText, "#") {
                $0.searchText = "#"
                // All tags + all priorities + all statuses
                $0.suggestedTokens = [
                    .tag(Tag(id: .tagAccessibility, name: "Accessibility & VoiceOver")),
                    .tag(Tag(id: .tagBug, name: "Bug")),
                    .tag(Tag(id: .tagCoreData, name: "Core Data")),
                    .tag(Tag(id: .tagNetworking, name: "Networking")),
                    .tag(Tag(id: .tagSwiftUI, name: "SwiftUI")),
                    .tag(Tag(id: .tagUIDesign, name: "UI Design")),
                    .priority(.low),
                    .priority(.medium),
                    .priority(.high),
                    .status(.open),
                    .status(.completed),
                ]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
        }

        @Test func suggestionsFilteredByQuery() async {
            await store.send(\.binding.searchText, "#sw") {
                $0.searchText = "#sw"
                $0.suggestedTokens = [
                    .tag(Tag(id: .tagSwiftUI, name: "SwiftUI")),
                ]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
        }

        @Test func suggestionsExcludeSelected() async {
            let swiftUITag = Tag(id: .tagSwiftUI, name: "SwiftUI")
            let token = SearchToken.tag(swiftUITag)
            await store.send(\.binding.searchTokens, [token]) {
                $0.searchTokens = [token]
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            // Now type "#sw" — SwiftUI should be excluded since already selected
            await store.send(\.binding.searchText, "#sw") {
                $0.searchText = "#sw"
                $0.suggestedTokens = []
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
        }

        @Test func suggestionsEmptyWithoutHash() async {
            await store.send(\.binding.searchText, "dark") {
                $0.searchText = "dark"
            }
            await store.receive(\.issueQueryChanged)
            await store.finish()
            #expect(store.state.suggestedTokens.isEmpty)
        }
    }
}
