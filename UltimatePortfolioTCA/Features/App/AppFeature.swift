import ComposableArchitecture

@Reducer struct AppFeature {
    @ObservableState struct State {
        var sidebar = SidebarFeature.State()
        var content: ContentFeature.State?
        var detail: DetailFeature.State?

        init() {
            self.content = ContentFeature.State(filter: .all)
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

        Reduce { state, action in
            switch action {
            case .sidebar(.binding(\.selectedFilter)),
                 .sidebar(.delegate(.selectedFilterChanged)):
                // Nothing to do if filter didn't change
                guard state.sidebar.selectedFilter != state.content?.filter else { return .none }
                // Reset content and detail if sidebar.selectedFilter nils out
                guard let sidebarFilter = state.sidebar.selectedFilter else {
                    state.content = nil
                    state.detail = nil
                    return .none
                }
                // If not nilled out, the filter has changed
                state.content = ContentFeature.State(filter: sidebarFilter)
                state.detail = nil
                return .none

            case .sidebar:
                return .none

            case .content(.binding(\.selectedIssue)),
                 .content(.delegate(.selectedIssueChanged)):
                // Nothing to do if issue didn't change
                guard state.content?.selectedIssue != state.detail?.issue else { return .none }
                // Reset detail if content.selectedIssue nils out
                guard let contentIssue = state.content?.selectedIssue else {
                    state.detail = nil
                    return .none
                }
                // If not nilled out, the issue has changed
                state.detail = DetailFeature.State(issue: contentIssue)
                return .none

            case .content:
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
