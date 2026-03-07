import ComposableArchitecture
import Foundation
import InlineSnapshotTesting
import SnapshotTestingCustomDump
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    // swiftlint:disable:next type_body_length
    @MainActor struct DetailFeatureTests {
        @Dependency(\.date.now) var now
        let store: TestStoreOf<DetailFeature>

        init() {
            store = TestStore(initialState: DetailFeature.State(issueID: .issueLoginLayout)) {
                DetailFeature()
            }
        }

        // MARK: - State snapshots

        @Test func defaultStateWithNoIssueFound() {
            let store = TestStore(initialState: DetailFeature.State(issueID: UUID(-1))) {
                DetailFeature()
            }
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                DetailFeature.State(
                  issueID: UUID(00000000-0000-0001-0000-000000000001),
                  _isEditing: false,
                  _draft: Issue.Draft(
                    id: nil,
                    title: "",
                    detail: "",
                    priority: .low,
                    isCompleted: false,
                    created: Date(2009-02-13T23:31:30.000Z),
                    modified: nil
                  ),
                  _selectedTagIDs: Set([]),
                  _issue: nil,
                  _tagRows: [
                    [0]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000006),
                        name: "Accessibility & VoiceOver"
                      ),
                      isAssigned: false
                    ),
                    [1]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000005),
                        name: "Bug"
                      ),
                      isAssigned: false
                    ),
                    [2]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000003),
                        name: "Core Data"
                      ),
                      isAssigned: false
                    ),
                    [3]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000002),
                        name: "Networking"
                      ),
                      isAssigned: false
                    ),
                    [4]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000001),
                        name: "SwiftUI"
                      ),
                      isAssigned: false
                    ),
                    [5]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000004),
                        name: "UI Design"
                      ),
                      isAssigned: false
                    )
                  ],
                  _alert: nil
                )
                """
            }
        }

        @Test func defaultStateWithIssue() {
            assertInlineSnapshot(of: store.state, as: .customDump) {
                """
                DetailFeature.State(
                  issueID: UUID(00000000-0000-0000-0000-00000000000A),
                  _isEditing: false,
                  _draft: Issue.Draft(
                    id: nil,
                    title: "",
                    detail: "",
                    priority: .low,
                    isCompleted: false,
                    created: Date(2009-02-13T23:31:30.000Z),
                    modified: nil
                  ),
                  _selectedTagIDs: Set([]),
                  _issue: Issue(
                    id: UUID(00000000-0000-0000-0000-00000000000A),
                    title: "Fix login screen layout",
                    detail: "The login button overlaps with the text field on smaller devices",
                    priority: .high,
                    isCompleted: false,
                    created: Date(2009-02-11T23:31:30.000Z),
                    modified: nil
                  ),
                  _tagRows: [
                    [0]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000006),
                        name: "Accessibility & VoiceOver"
                      ),
                      isAssigned: false
                    ),
                    [1]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000005),
                        name: "Bug"
                      ),
                      isAssigned: true
                    ),
                    [2]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000003),
                        name: "Core Data"
                      ),
                      isAssigned: false
                    ),
                    [3]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000002),
                        name: "Networking"
                      ),
                      isAssigned: false
                    ),
                    [4]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000001),
                        name: "SwiftUI"
                      ),
                      isAssigned: true
                    ),
                    [5]: TagRow(
                      tag: Tag(
                        id: UUID(00000000-0000-0000-0000-000000000004),
                        name: "UI Design"
                      ),
                      isAssigned: false
                    )
                  ],
                  _alert: nil
                )
                """
            }
        }

        // MARK: - Create new issue

        @Test func createNewIssueButtonTappedSendsDelegateAction() async {
            await store.send(\.view.createIssueButtonTapped)
            await store.receive(\.delegate.createIssue)
        }

        // MARK: - Edit

        @Test func editButtonTapped() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
        }

        @Test func editButtonTappedWithNoIssueFound() async {
            let store = TestStore(initialState: DetailFeature.State(issueID: UUID(-1))) {
                DetailFeature()
            }
            // No state changes, edit button should not be tapable without an issue
            await store.send(\.view.editButtonTapped)
        }

        @Test func cancelEditButtonTapped() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
            await store.send(\.view.cancelEditButtonTapped) {
                $0.draft = Issue.Draft(created: now)
                $0.selectedTagIDs = []
                $0.isEditing = false
            }
        }

        // MARK: - Save

        @Test func saveNewIssue() async {
            let store = TestStore(initialState: DetailFeature.State(issueID: UUID(-1))) {
                DetailFeature()
            }
            await store.send(\.view.createIssueButtonTapped)
            await store.receive(\.delegate.createIssue)
            let newDraft = Issue.Draft(id: UUID(-1), title: "New Issue", created: now)
            await store.send(\.binding.draft, newDraft) {
                $0.draft = newDraft
            }
            await store.send(\.binding.selectedTagIDs, [.tagSwiftUI]) {
                $0.selectedTagIDs = [.tagSwiftUI]
            }
            await store.send(\.view.saveButtonTapped)
            await store.receive(\.delegate.issueSaved)
            await store.finish()
        }

        @Test func saveEditWithChanges() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
            var updatedDraft = store.state.draft
            updatedDraft.title = "Updated title"
            await store.send(\.binding.draft, updatedDraft) {
                $0.draft.title = "Updated title"
            }
            await store.send(\.view.saveButtonTapped)
            await store.receive(\.delegate.issueSaved)
            await store.finish()
        }

        @Test func saveEditWithNoChanges() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
            // Save without changes — no-op, no effect emitted
            await store.send(\.view.saveButtonTapped) {
                $0.draft = Issue.Draft(created: now)
                $0.selectedTagIDs = []
                $0.isEditing = false
            }
            await store.finish()
        }

        @Test func saveEditWithOnlyTagChanges() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
            // Remove all tags
            await store.send(\.binding.selectedTagIDs, []) {
                $0.selectedTagIDs = []
            }
            // Add a new tag
            await store.send(\.binding.selectedTagIDs, [.tagSwiftUI]) {
                $0.selectedTagIDs = [.tagSwiftUI]
            }
            await store.send(\.view.saveButtonTapped)
            await store.receive(\.delegate.issueSaved)
            await store.finish()
        }

        @Test func saveEditWithNoIssueFound() async {
            // Simulate a `nil` id for draft
            let store = TestStore(initialState: DetailFeature.State(issueID: UUID(-1), isEditing: true)) {
                DetailFeature()
            }
            // Update the draft
            var updatedDraft = store.state.draft
            updatedDraft.title = "Updated title"
            await store.send(\.binding.draft, updatedDraft) {
                $0.draft.title = "Updated title"
            }
            await store.send(\.view.saveButtonTapped)
            // No run effect to exhaust
        }

        // MARK: - Create tag

        @Test func createTagButtonTappedFromNewIssue() async {
            await store.send(\.view.createIssueButtonTapped)
            await store.receive(\.delegate.createIssue)
            await store.send(\.view.createTagButtonTapped) {
                $0.selectedTagIDs = [UUID(0)]
            }
            await store.receive(\.delegate.createTag, UUID(0))
        }

        @Test func createTagButtonTappedFromEditIssue() async throws {
            let issue = try #require(store.state.issue)
            let assignedTagIDs = Set(store.state.tagRows.filter(\.isAssigned).map(\.tag.id))
            let newTagIDs = assignedTagIDs.union([UUID(0)])
            await store.send(\.view.editButtonTapped) {
                $0.draft = Issue.Draft(issue)
                $0.selectedTagIDs = assignedTagIDs
                $0.isEditing = true
            }
            await store.send(\.view.createTagButtonTapped) {
                $0.selectedTagIDs = newTagIDs
            }
            await store.receive(\.delegate.createTag, UUID(0))
            #expect(store.state.selectedTagIDs == newTagIDs)
        }

        // MARK: - Delete

        @Test func deleteButtonTapped() async {
            await store.send(\.view.deleteButtonTapped) {
                $0.alert = AlertState {
                    TextState("Delete Issue")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                } message: {
                    TextState(
                        "Are you sure you want to delete this issue? This action cannot be undone."
                    )
                }
            }
        }

        @Test func confirmDeletion() async {
            await store.send(\.view.deleteButtonTapped) {
                $0.alert = AlertState {
                    TextState("Delete Issue")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                } message: {
                    TextState(
                        "Are you sure you want to delete this issue? This action cannot be undone."
                    )
                }
            }
            await store.send(\.alert.presented.confirmDeletion) {
                $0.alert = nil
            }
            await store.receive(\.delegate.issueDeleted)
            await store.finish()
        }

        @Test func confirmDeletionWithNoIssueFound() async {
            let store = TestStore(initialState: DetailFeature.State(issueID: UUID(-1))) {
                DetailFeature()
            }
            await store.send(\.view.deleteButtonTapped) {
                $0.alert = AlertState {
                    TextState("Delete Issue")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                } message: {
                    TextState(
                        "Are you sure you want to delete this issue? This action cannot be undone."
                    )
                }
            }
            await store.send(\.alert.presented.confirmDeletion) {
                $0.alert = nil
            }
            await store.receive(\.delegate.issueDeleted)
            await store.finish()
        }
    }
}
