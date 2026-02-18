import ComposableArchitecture
import SQLiteData
import SwiftUI

/// Query result combining a ``Tag`` with a Bool indicating whether it is assigned to the current issue.
/// Produced by ``DetailFeature/State/tagQuery`` via a subquery on ``IssueTag``.
@Selection struct TagRow: Identifiable {
    var tag: Tag
    var isAssigned: Bool
    var id: Tag.ID { tag.id }
}

@Reducer struct DetailFeature {
    @ObservableState struct State {
        let issueID: Issue.ID
        @FetchOne var issue: Issue?
        @FetchAll var tagRows: [TagRow] = []

        var isEditing: Bool = false
        var draft: Issue.Draft = Issue.Draft()
        var selectedTagIDs: Set<Tag.ID> = []

        /// Sets up database observations (`@FetchOne`, `@FetchAll`) for the issue and its tags.
        init(issueID: Issue.ID) {
            self.issueID = issueID
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
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case view(View)

        enum Delegate {
            case issueDeleted
        }

        enum View {
            case editButtonTapped
            case cancelEditButtonTapped
            case saveButtonTapped
            case deleteButtonTapped
        }
    }

    @Dependency(\.defaultDatabase) var database

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .delegate:
                return .none

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
                let issueID = state.issueID
                let selectedTagIDs = state.selectedTagIDs
                let draft = state.draft
                resetDraftState(&state)
                return .run { [database] _ in
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
                    }
                }

            case .view(.deleteButtonTapped):
                resetDraftState(&state)
                let issueID = state.issueID
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Issue.find(issueID).delete().execute(db)
                        }
                    }
                    await send(.delegate(.issueDeleted))
                }
            }
        }
    }

    private func resetDraftState(_ state: inout State) {
        state.draft = Issue.Draft()
        state.selectedTagIDs = []
        state.isEditing = false
    }
}
