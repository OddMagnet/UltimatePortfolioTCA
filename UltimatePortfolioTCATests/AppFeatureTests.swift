import ComposableArchitecture
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    // swiftlint:disable:next type_body_length
    @MainActor struct AppFeatureTests {
        @Dependency(\.date.now) var now
        let store: TestStoreOf<AppFeature>

        init() {
            store = TestStore(initialState: AppFeature.State(selectedFilter: .open)) {
                AppFeature()
            }
        }

        // MARK: - State snapshots

        // swiftlint:disable:next function_body_length
        @Test func defaultAppStoreState() {
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                AppFeature.State(
                  _sidebar: SidebarFeature.State(
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
                  ),
                  _content: ContentFeature.State(
                    _filter: .open,
                    _selectedIssueID: nil,
                    _searchText: "",
                    _searchTokens: [],
                    _suggestedTokens: [],
                    _showCompleted: #1 Bool(↩︎),
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
                  ),
                  _detail: nil,
                  _destination: nil
                )
                """
            }
        }

        // MARK: - Filter changed

        @Test func selectedFilterChangedToTag() async {
            let testTag = Tag(id: UUID(-1), name: "Test")
            await store.send(\.sidebar.binding.selectedFilter, .tag(testTag)) {
                $0.sidebar.selectedFilter = .tag(testTag)
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .tag(testTag)) {
                $0.content = ContentFeature.State(filter: .tag(testTag))
                $0.detail = nil
            }
        }

        @Test func selectedFilterChangedToNil() async {
            await store.send(\.sidebar.binding.selectedFilter, nil) {
                $0.sidebar.selectedFilter = nil
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, nil) {
                $0.content = nil
                $0.detail = nil
            }
        }

        @Test func selectedFilterChangedToOtherSmartFilter() async {
            await store.send(\.sidebar.binding.selectedFilter, .completed) {
                $0.sidebar.selectedFilter = .completed
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .completed) {
                $0.content = ContentFeature.State(filter: .completed)
                $0.detail = nil
            }
        }

        // MARK: - Issue Creation / Saving

        @Test func createIssueFromAppView() async {
            let newIssueID = UUID(0)
            await store.send(\.view.createIssueButtonTapped) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
            }
        }

        @Test func createIssueFromAppViewWithSelectedTagFiler() async {
            let newIssueID = UUID(0)
            let selectedTag = Tag(id: UUID(-1), name: "Test")
            await store.send(\.sidebar.binding.selectedFilter, .tag(selectedTag)) {
                $0.sidebar.selectedFilter = .tag(selectedTag)
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .tag(selectedTag)) {
                $0.content = ContentFeature.State(filter: .tag(selectedTag))
            }
            await store.send(\.view.createIssueButtonTapped) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
                $0.detail?.selectedTagIDs = [selectedTag.id]
            }
        }

        @Test func createIssueFromContent() async {
            let newIssueID = UUID(0)
            await store.send(\.content.delegate.createIssue) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
            }
        }

        @Test func createIssueFromContentWithSelectedTagFilter() async {
            let newIssueID = UUID(0)
            let selectedTag = Tag(id: UUID(-1), name: "Test")
            await store.send(\.sidebar.binding.selectedFilter, .tag(selectedTag)) {
                $0.sidebar.selectedFilter = .tag(selectedTag)
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .tag(selectedTag)) {
                $0.content = ContentFeature.State(filter: .tag(selectedTag))
            }
            await store.send(\.content.delegate.createIssue) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
                $0.detail?.selectedTagIDs = [selectedTag.id]
            }
        }

        @Test func createIssueFromDetailWithSelectedTagFilter() async {
            let newIssueID = UUID(0)
            let selectedTag = Tag(id: UUID(-1), name: "Test")
            await store.send(\.sidebar.binding.selectedFilter, .tag(selectedTag)) {
                $0.sidebar.selectedFilter = .tag(selectedTag)
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .tag(selectedTag)) {
                $0.content = ContentFeature.State(filter: .tag(selectedTag))
            }
            await store.send(\.content.binding.selectedIssueID, .issueLoginLayout) {
                $0.content?.selectedIssueID = .issueLoginLayout
            }
            await store.receive(\.content.delegate.selectedIssueChanged, .issueLoginLayout) {
                $0.detail = DetailFeature.State(issueID: .issueLoginLayout)
            }
            await store.send(\.detail.delegate.createIssue) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
                $0.detail?.selectedTagIDs = [selectedTag.id]
            }
        }

        @Test func issueSavedFromDetail() async {
            let newIssueID = UUID(0)
            await store.send(\.content.delegate.createIssue) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID, isEditing: true)
                $0.detail?.draft = Issue.Draft(id: newIssueID, created: now)
            }
            await store.send(\.detail.delegate.issueSaved, newIssueID) {
                $0.content?.selectedIssueID = newIssueID
                $0.detail = DetailFeature.State(issueID: newIssueID)
            }
        }

        // MARK: - Issue Selection / Deletion

        @Test func selectedIssueChangedToIssue() async {
            let testIssueId = UUID(-1)
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
        }

        @Test func selectedIssueChangedToNil() async {
            let issueID = UUID(-1)
            // First select an issue
            await store.send(\.content.binding.selectedIssueID, issueID) {
                $0.content?.selectedIssueID = issueID
            }
            await store.receive(\.content.delegate.selectedIssueChanged, issueID) {
                $0.content?.selectedIssueID = issueID
                $0.detail = DetailFeature.State(issueID: issueID)
            }
            // Then test the deselect
            await store.send(\.content.delegate.selectedIssueChanged, nil) {
                $0.detail = nil
            }
        }

        @Test func selectedIssueChangedToSameIssue() async {
            let testIssueId = UUID(-1)
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId)
        }

        @Test func issueDeleted() async {
            let testIssueId = UUID(-1)
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.detail.delegate.issueDeleted) {
                $0.content?.selectedIssueID = nil
                $0.detail = nil
            }
        }

        // MARK: - Issue completion toggled

        @Test func issueCompletedToggledFromOpenFilter() async {
            let testIssueId = UUID(-1)
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.detail.delegate.issueCompletedToggled) {
                $0.content?.selectedIssueID = nil
                $0.detail = nil
            }
        }

        @Test func issueCompletedToggledFromCompletedFilter() async {
            let testIssueId = UUID(-1)
            await store.send(\.sidebar.binding.selectedFilter, .completed) {
                $0.sidebar.selectedFilter = .completed
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .completed) {
                $0.content = ContentFeature.State(filter: .completed)
            }
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.detail.delegate.issueCompletedToggled) {
                $0.content?.selectedIssueID = nil
                $0.detail = nil
            }
        }

        @Test func issueCompletedToggledFromTagFilterWithShowCompletedFalse() async {
            let testIssueId = UUID.issueLoginLayout
            let selectedFilter: IssueFilter = .tag(Tag(id: .tagSwiftUI, name: "SwiftUI"))
            await store.send(\.sidebar.binding.selectedFilter, selectedFilter) {
                $0.sidebar.selectedFilter = selectedFilter
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, selectedFilter) {
                $0.content = ContentFeature.State(filter: selectedFilter)
            }
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.detail.delegate.issueCompletedToggled) {
                $0.content?.selectedIssueID = nil
                $0.detail = nil
            }
        }

        @Test func issueCompletedToggledFromTagFilterWithShowCompletedTrue() async {
            let testIssueId = UUID.issueLoginLayout
            let selectedFilter: IssueFilter = .tag(Tag(id: .tagSwiftUI, name: "SwiftUI"))
            await store.send(\.sidebar.binding.selectedFilter, selectedFilter) {
                $0.sidebar.selectedFilter = selectedFilter
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, selectedFilter) {
                $0.content = ContentFeature.State(filter: selectedFilter)
            }
            await store.send(\.content.binding.showCompleted, true) {
                $0.content?.$showCompleted.withLock { $0 = true }
            }
            await store.receive(\.content.issueQueryChanged, nil)
            await store.send(\.content.delegate.selectedIssueChanged, testIssueId) {
                $0.detail = DetailFeature.State(issueID: testIssueId)
            }
            await store.send(\.detail.delegate.issueCompletedToggled)
        }

        // MARK: - Tag creation / renaming

        @Test func createTagFromSidebar() async {
            let testTagId = UUID(-1)
            await store.send(\.sidebar.delegate.createTag, testTagId) {
                $0.destination = .alert(Tag.Draft(id: testTagId))
            }
        }

        @Test func createTagFromDetail() async {
            let testTagId = UUID(-1)
            await store.send(\.binding.detail, DetailFeature.State(issueID: UUID(-1))) {
                $0.detail = DetailFeature.State(issueID: UUID(-1))
            }
            await store.send(\.detail.delegate.createTag, testTagId) {
                $0.destination = .alert(Tag.Draft(id: testTagId))
            }
        }

        @Test func renameTag() async {
            let testTag = Tag(id: UUID(-1), name: "TestTag")
            await store.send(\.sidebar.delegate.renameTag, testTag) {
                $0.destination = .alert(Tag.Draft(testTag))
            }
        }

        // MARK: - Tag Alert

        @Test func tagAlertConfirmCreatesTag() async {
            let tagId = UUID(-1)
            await store.send(\.sidebar.delegate.createTag, tagId) {
                $0.destination = .alert(Tag.Draft(id: tagId))
            }
            let newTag = Tag.Draft(id: tagId, name: "TestTag")
            await store.send(\.binding.destination, .alert(newTag)) {
                $0.destination = .alert(newTag)
            }
            await store.send(\.view.tagAlertConfirmButtonTapped) {
                $0.destination = nil
            }
            await store.finish()
        }

        @Test func tagAlertConfirmWithEmptyOrWhiteSpaceName() async {
            let tagId = UUID(-1)
            // Empty name
            await store.send(\.sidebar.delegate.createTag, tagId) {
                $0.destination = .alert(Tag.Draft(id: tagId))
            }
            await store.send(\.view.tagAlertConfirmButtonTapped) {
                $0.destination = nil
            }
            await store.finish()
            // Whitespace only name
            let whiteSpaceOnlyTag = Tag.Draft(id: tagId, name: "  ")
            await store.send(\.sidebar.delegate.createTag, tagId) {
                $0.destination = .alert(Tag.Draft(id: tagId))
            }
            await store.send(\.binding.destination, .alert(whiteSpaceOnlyTag)) {
                $0.destination = .alert(whiteSpaceOnlyTag)
            }
            await store.send(\.view.tagAlertConfirmButtonTapped) {
                $0.destination = nil
            }
            await store.finish()
        }

        @Test func tagAlertConfirmRenamesSelectedTag() async {
            let tagID = UUID(-1)
            let testTag = Tag(id: tagID, name: "TestTag")
            let newTag = Tag(id: tagID, name: "NewNameTag")
            await store.send(\.sidebar.binding.selectedFilter, .tag(testTag)) {
                $0.sidebar.selectedFilter = .tag(testTag)
            }
            await store.receive(\.sidebar.delegate.selectedFilterChanged, .tag(testTag)) {
                $0.content = ContentFeature.State(filter: .tag(testTag))
            }
            await store.send(\.sidebar.delegate.renameTag, testTag) {
                $0.destination = .alert(Tag.Draft(testTag))
            }
            await store.send(\.binding.destination, .alert(Tag.Draft(newTag))) {
                $0.destination = .alert(Tag.Draft(newTag))
            }
            await store.send(\.view.tagAlertConfirmButtonTapped) {
                $0.destination = nil
            }
            await store.receive(\.selectedTagRenamed, newTag) {
                $0.sidebar.selectedFilter = .tag(newTag)
                $0.content?.filter = .tag(newTag)
            }
            await store.finish()
        }

        @Test func tagAlertConfirmRenamesTag() async {
            let tagID = UUID(-1)
            let testTag = Tag(id: tagID, name: "TestTag")
            let newTag = Tag(id: tagID, name: "NewNameTag")
            await store.send(\.sidebar.delegate.renameTag, testTag) {
                $0.destination = .alert(Tag.Draft(testTag))
            }
            await store.send(\.binding.destination, .alert(Tag.Draft(newTag))) {
                $0.destination = .alert(Tag.Draft(newTag))
            }
            await store.send(\.view.tagAlertConfirmButtonTapped) {
                $0.destination = nil
            }
            // No `.selectedTagRenamed` is received
            await store.finish()
        }

        @Test func selectedTagRenamed() async {
            let newTag = Tag(id: UUID(-1), name: "NewNameTag")
            await store.send(\.selectedTagRenamed, newTag) {
                $0.sidebar.selectedFilter = .tag(newTag)
                $0.content?.filter = .tag(newTag)
            }
        }

        // MARK: - Awards Sheet

        @Test func showAwardsDelegate() async {
            await store.send(\.sidebar.delegate.showAwards) {
                $0.destination = .awards
            }
        }
    }
}
