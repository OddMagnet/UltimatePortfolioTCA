import ComposableArchitecture

@Reducer struct ContentFeature {
    @ObservableState struct State {
        var filter: IssueFilter
        var selectedIssue: Issue?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
    }
}
