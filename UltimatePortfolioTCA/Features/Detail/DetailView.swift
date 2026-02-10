import ComposableArchitecture
import SwiftUI

struct DetailView: View {
    let store: StoreOf<DetailFeature>

    var body: some View {
        Form {
            Section("Title") {
                Text(store.issue.title)
            }

            Section("Detail") {
                Text(store.issue.detail)
            }
        }
        .navigationTitle(store.issue.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        DetailView(store: Store(
            initialState: DetailFeature.State(
                issue: Issue(id: UUID(), title: "Example Issue", detail: "Some details here", modified: nil)
            ),
            reducer: { DetailFeature() },
            withDependencies: { try! $0.bootstrapDatabase() }
        ))
    }
}
