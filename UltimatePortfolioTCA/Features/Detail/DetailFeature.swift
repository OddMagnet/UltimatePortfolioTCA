import ComposableArchitecture

@Reducer struct DetailFeature {
    @ObservableState struct State {
        var issue: Issue
    }

    enum Action {}

    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
