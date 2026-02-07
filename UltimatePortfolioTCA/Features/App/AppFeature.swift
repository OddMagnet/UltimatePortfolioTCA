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
            case .sidebar(.binding(\.selectedFilter)):
                if let filter = state.sidebar.selectedFilter {
                    state.content = ContentFeature.State(filter: filter)
                } else {
                    state.content = nil
                }
                state.detail = nil
                return .none

            case .sidebar:
                return .none

            case .content(.binding(\.selectedIssue)):
                if let issue = state.content?.selectedIssue {
                    state.detail = DetailFeature.State(issue: issue)
                } else {
                    state.detail = nil
                }
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
