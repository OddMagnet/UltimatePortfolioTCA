import ComposableArchitecture
import SQLiteData
import SwiftUI

@Reducer struct DetailFeature {
    @ObservableState struct State {
        let issueID: Issue.ID
        @FetchOne var issue: Issue?

        /// Sets up a database observation (`@FetchOne`) to watch the issue with the given ID.
        init(issueID: Issue.ID) {
            self.issueID = issueID
            _issue = FetchOne(Issue.find(issueID), animation: .default)
        }
    }

    enum Action {}

    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
