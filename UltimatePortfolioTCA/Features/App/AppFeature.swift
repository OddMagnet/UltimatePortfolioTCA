import ComposableArchitecture
import Foundation
import SQLiteData

@Reducer struct AppFeature {
    @ObservableState struct State: Equatable {
        var sidebar: SidebarFeature.State
        var content: ContentFeature.State?
        var detail: DetailFeature.State?
        var destination: Destination?

        init(selectedFilter: IssueFilter? = nil, selectedIssueID: Issue.ID? = nil) {
            sidebar = SidebarFeature.State(selectedFilter: selectedFilter)
            guard let selectedFilter else { return }
            content = ContentFeature.State(filter: selectedFilter, selectedIssueID: selectedIssueID)
            guard let selectedIssueID else { return }
            detail = DetailFeature.State(issueID: selectedIssueID)
        }
    }

    @CasePathable
    enum Destination: Equatable {
        case alert(Tag.Draft)
        case awards
    }

    enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case content(ContentFeature.Action)
        case detail(DetailFeature.Action)
        case sidebar(SidebarFeature.Action)
        case selectedTagRenamed(Tag)
        case view(View)

        @CasePathable
        enum View {
            case createIssueButtonTapped
            case tagAlertConfirmButtonTapped
        }
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.sidebar, action: \.sidebar) {
            SidebarFeature()
        }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case let .sidebar(.delegate(.createTag(tagID))),
                 let .detail(.delegate(.createTag(tagID))):
                state.destination = .alert(Tag.Draft(id: tagID))
                return .none

            case let .sidebar(.delegate(.renameTag(tag))):
                state.destination = .alert(Tag.Draft(tag))
                return .none

            case let .sidebar(.delegate(.selectedFilterChanged(newFilter))):
                // Nothing to do if filter didn't change
                guard newFilter != state.content?.filter else { return .none }
                // Reset content and detail if the new filter is nil
                guard let newFilter else {
                    state.content = nil
                    state.detail = nil
                    return .none
                }
                // If not nil, the filter has changed
                state.content = ContentFeature.State(filter: newFilter)
                state.detail = nil
                return .none

            case .sidebar(.delegate(.showAwards)):
                state.destination = .awards
                return .none

            case .sidebar:
                return .none

            case .content(.delegate(.createIssue)),
                 .detail(.delegate(.createIssue)),
                 .view(.createIssueButtonTapped):
                let issueID = uuid()
                let currentFilter = state.content?.filter ?? .open
                state.sidebar.selectedFilter = currentFilter
                if state.content == nil {
                    state.content = ContentFeature.State(filter: currentFilter, selectedIssueID: issueID)
                } else {
                    state.content?.selectedIssueID = issueID
                }
                state.detail = DetailFeature.State(issueID: issueID, isEditing: true)
                state.detail?.draft = Issue.Draft(id: issueID, created: now, modified: now)
                if case let .tag(tag) = currentFilter {
                    state.detail?.selectedTagIDs = [tag.id]
                }
                return .none

            case let .content(.delegate(.selectedIssueChanged(newIssueID))):
                // Nothing to do if issue didn't change
                guard newIssueID != state.detail?.issueID else { return .none }
                // Reset detail if the new issue is nil
                guard let newIssueID else {
                    state.detail = nil
                    return .none
                }
                // If not nil, the issue has changed
                state.detail = DetailFeature.State(issueID: newIssueID)
                return .none

            case .content:
                return .none

            case .detail(.delegate(.issueDeleted)):
                state.content?.selectedIssueID = nil
                state.detail = nil
                return .none

            case let .detail(.delegate(.issueSaved(newIssueID))):
                state.content?.selectedIssueID = newIssueID
                state.detail = DetailFeature.State(issueID: newIssueID)
                return .none

            case .detail(.delegate(.issueCompletedToggled)):
                // If one of the following is true, issue would disappear in Content's list
                guard state.content?.filter == .open // Open -> Closed
                    || state.content?.filter == .completed // Closed -> Open
                    || state.content?.showCompleted == false // Open -> Closed, covers tag & recent filters
                else { return .none }
                // Then we need to reset state
                state.content?.selectedIssueID = nil
                state.detail = nil
                return .none

            case .detail:
                return .none

            case let .selectedTagRenamed(renamedTag):
                state.sidebar.selectedFilter = .tag(renamedTag)
                state.content?.filter = .tag(renamedTag)
                return .none

            case .view(.tagAlertConfirmButtonTapped):
                defer { state.destination = nil }
                guard case let .alert(tagDraft) = state.destination, let id = tagDraft.id else { return .none }
                let name = tagDraft.name.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return .none }
                let newTagDraft = Tag.Draft(id: id, name: name)
                let is​Renaming​Selected​Tag = switch state.sidebar.selectedFilter {
                case let .tag(selectedTag): selectedTag.id == id
                default: false
                }
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Tag.upsert { newTagDraft }.execute(db)
                        }
                    }
                    if is​Renaming​Selected​Tag {
                        let renamedTag = await withErrorReporting {
                            try await database.read { db in
                                try Tag.find(id).fetchOne(db)
                            }
                        }
                        guard let renamedTag else { return }
                        await send(.selectedTagRenamed(renamedTag))
                    }
                }
            }
        }
        .ifLet(\.content, action: \.content) {
            ContentFeature()
        }
        .ifLet(\.detail, action: \.detail) {
            DetailFeature()
        }
    }
}
