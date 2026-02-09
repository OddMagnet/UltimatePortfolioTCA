import ComposableArchitecture

@Reducer struct SidebarFeature {
    @ObservableState struct State {
        var selectedFilter: IssueFilter? = .all
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
    }
}
