import ComposableArchitecture
import Foundation
import SQLiteData

@Reducer struct AppFeature {
    @ObservableState struct State {
        var sidebar = SidebarFeature.State()
        var content: ContentFeature.State?
        var detail: DetailFeature.State
        var tagDraft: Tag.Draft?

        init() {
            content = ContentFeature.State(filter: .open)
            detail = DetailFeature.State(issueID: nil)
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case content(ContentFeature.Action)
        case detail(DetailFeature.Action)
        case sidebar(SidebarFeature.Action)
        case selectedTagRenamed(Tag)
        case tagAlertConfirmButtonTapped
    }

    @Dependency(\.defaultDatabase) var database
    @Dependency(\.uuid) var uuid

    var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.sidebar, action: \.sidebar) {
            SidebarFeature()
        }

        Scope(state: \.detail, action: \.detail) {
            DetailFeature()
        }

        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case .sidebar(.delegate(.createTag)),
                 .detail(.delegate(.createTag)):
                state.tagDraft = Tag.Draft(id: uuid())
                return .none

            case let .sidebar(.delegate(.renameTag(tag))):
                state.tagDraft = Tag.Draft(tag)
                return .none

            case let .sidebar(.delegate(.selectedFilterChanged(newFilter))):
                // Nothing to do if filter didn't change
                guard newFilter != state.content?.filter else { return .none }
                // Reset content and detail if the new filter is nil
                guard let newFilter else {
                    state.content = nil
                    state.detail = DetailFeature.State(issueID: nil)
                    return .none
                }
                // If not nil, the filter has changed
                state.content = ContentFeature.State(filter: newFilter)
                state.detail = DetailFeature.State(issueID: nil)
                return .none

            case .sidebar:
                return .none

            case let .content(.delegate(.selectedIssueChanged(newIssueID))):
                // Nothing to do if issue didn't change
                guard newIssueID != state.detail.issueID else { return .none }
                // Reset detail if the new issue is nil
                guard let newIssueID else {
                    state.detail = DetailFeature.State(issueID: nil)
                    return .none
                }
                // If not nil, the issue has changed
                state.detail = DetailFeature.State(issueID: newIssueID)
                return .none

            case .content:
                return .none

            case .detail(.delegate(.issueDeleted)):
                state.detail = DetailFeature.State(issueID: nil)
                state.content?.selectedIssueID = nil
                return .none

            case .detail:
                return .none

            case let .selectedTagRenamed(renamedTag):
                state.sidebar.selectedFilter = .tag(renamedTag)
                state.content?.filter = .tag(renamedTag)
                return .none

            case .tagAlertConfirmButtonTapped:
                guard let id = state.tagDraft?.id,
                      let name = state.tagDraft?.name.trimmingCharacters(in: .whitespaces),
                      !name.isEmpty else { return .none }
                let tagDraft = Tag.Draft(id: id, name: name)
                let is​Renaming​Selected​Tag = switch state.sidebar.selectedFilter {
                case let .tag(selectedTag): selectedTag.id == id
                default: false
                }
                state.tagDraft = nil
                return .run { [database] send in
                    await withErrorReporting {
                        try await database.write { db in
                            try Tag.upsert { tagDraft }.execute(db)
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
    }
}
