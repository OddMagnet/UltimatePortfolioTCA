import ComposableArchitecture

@Reducer struct ContentFeature {
    @ObservableState struct State {
        var filter: SidebarFeature.State.Filter
        var selectedIssue: Issue?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
    }
}
