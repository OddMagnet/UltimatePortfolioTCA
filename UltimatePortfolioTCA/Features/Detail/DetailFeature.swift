import ComposableArchitecture
import SQLiteData
import SwiftUI

/// Query result combining a ``Tag`` with a Bool indicating whether it is assigned to the current issue.
/// Produced by ``DetailFeature/State/tagQuery`` via a subquery on ``IssueTag``.
@Selection struct TagRow: Equatable, Identifiable {
    var tag: Tag
    var isAssigned: Bool
    var isNotAssigned: Bool { !isAssigned }
    var id: Tag.ID { tag.id }
}

@Reducer struct DetailFeature {
    @ObservableState struct State: Equatable {
        let issueID: Issue.ID
        var isEditing: Bool
        var draft: Issue.Draft
        var selectedTagIDs: Set<Tag.ID> = []

        @FetchOne var issue: Issue?
        @FetchAll var tagRows: [TagRow] = []

        @Presents var alert: AlertState<Action.Alert>?

        /// Sets up database observations (`@FetchOne`, `@FetchAll`) for the issue and its tags.
        init(issueID: Issue.ID, isEditing: Bool = false) {
            self.issueID = issueID
            self.isEditing = isEditing
            @Dependency(\.date.now) var now
            draft = Issue.Draft(created: now, modified: now)

            _issue = FetchOne(Issue.find(issueID), animation: .default)
            _tagRows = FetchAll(tagQuery, animation: .default)
        }

        /// All tags ordered by name, each with a Bool indicating assignment to this issue via subquery.
        var tagQuery: some Statement<TagRow> {
            Tag
                .order(by: \.name)
                .select {
                    TagRow.Columns(
                        tag: $0,
                        isAssigned: $0.id.in(
                            IssueTag.select(\.tagID).where { $0.issueID.eq(issueID) }
                        )
                    )
                }
        }
    }

    enum Action: BindableAction, ViewAction {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case view(View)

        @CasePathable
        enum Alert {
            case confirmDeletion
        }

        @CasePathable
        enum Delegate {
            case createIssue
            case createTag(Tag.ID)
            case issueDeleted
            case issueSaved(Issue.ID)
            case issueCompletedToggled
        }

        @CasePathable
        enum View {
            case createIssueButtonTapped
            case createTagButtonTapped
            case editButtonTapped
            case cancelEditButtonTapped
            case saveButtonTapped
            case deleteButtonTapped
            case toggleIssueCompletedButtonTapped
        }
    }

    @Dependency(\.date.now) var now
    @Dependency(\.defaultDatabase) var database
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .delegate:
                return .none

            case .view(.createIssueButtonTapped):
                return .send(.delegate(.createIssue))

            case .view(.createTagButtonTapped):
                let tagID = uuid()
                state.selectedTagIDs.insert(tagID)
                return .send(.delegate(.createTag(tagID)))

            case .view(.editButtonTapped):
                guard let issue = state.issue else { return .none }
                state.draft = Issue.Draft(issue)
                state.selectedTagIDs = Set(state.tagRows.filter(\.isAssigned).map(\.tag.id))
                state.isEditing = true
                return .none

            case .view(.cancelEditButtonTapped):
                resetDraftState(&state)
                return .none

            case .view(.saveButtonTapped):
                guard userDidModifyDraft(state) else {
                    resetDraftState(&state)
                    return .none
                }
                // For new issue creation, the draft was assigned a uuid at creation
                // For editing an issue, the id of the draft comes from Issue.Draft(state.issue)
                // If it's nil, we need to abort early
                guard let issueID = state.draft.id else { return .none }
                let selectedTagIDs = state.selectedTagIDs
                let draft = state.draft
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.upsert { draft }.execute(db)
                            try IssueTag.where { $0.issueID.eq(issueID) }.delete().execute(db)
                            for tagID in selectedTagIDs {
                                try IssueTag.upsert {
                                    IssueTag.Draft(issueID: issueID, tagID: tagID)
                                }.execute(db)
                            }
                        }
                        await send(.delegate(.issueSaved(issueID)))
                    }
                }

            case .view(.deleteButtonTapped):
                state.alert = AlertState {
                    TextState("Delete Issue")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                } message: {
                    TextState("Are you sure you want to delete this issue? This action cannot be undone.")
                }
                return .none

            case .view(.toggleIssueCompletedButtonTapped):
                guard let issue = state.issue else { return .none }
                var draft = Issue.Draft(issue)
                draft.isCompleted.toggle()
                return .run { [database, draft] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.upsert { draft }.execute(db)
                        }
                    }
                    await send(.delegate(.issueCompletedToggled))
                }

            case .alert(.presented(.confirmDeletion)):
                let issueID = state.issueID
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.find(issueID).delete().execute(db)
                        }
                    }
                    await send(.delegate(.issueDeleted))
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    private func resetDraftState(_ state: inout State) {
        state.draft = Issue.Draft(created: now, modified: now)
        state.selectedTagIDs = []
        state.isEditing = false
    }

    private func userDidModifyDraft(_ state: State) -> Bool {
        // No currentIssue should never happen, but if it does that means a draft will contain new data
        guard let currentIssue = state.issue else { return true }
        let draftContainsChanges = state.draft != Issue.Draft(currentIssue)
        let assignedTagIDs = state.tagRows.filter(\.isAssigned).map(\.id)
        let selectedTagsChanged = Set(assignedTagIDs) != state.selectedTagIDs
        return draftContainsChanges || selectedTagsChanged
    }
}
