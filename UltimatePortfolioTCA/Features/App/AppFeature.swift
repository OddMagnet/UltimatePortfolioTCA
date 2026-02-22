import ComposableArchitecture

@Reducer struct AppFeature {
    @ObservableState struct State {
        var sidebar = SidebarFeature.State()
        var content: ContentFeature.State?
        var detail: DetailFeature.State?

        init() {
            content = ContentFeature.State(filter: .open)
        }
    }

    enum Action {
        case sidebar(SidebarFeature.Action)
        case content(ContentFeature.Action)
        case detail(DetailFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.sidebar, action: \.sidebar) {
            SidebarFeature()
        }

        Reduce<State, Action> { state, action in
            switch action {
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

            case .sidebar:
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
                state.detail = nil
                state.content?.selectedIssueID = nil
                return .none

            case .detail:
                return .none
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
