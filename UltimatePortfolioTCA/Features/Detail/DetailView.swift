import ComposableArchitecture
import SwiftUI

struct DetailView: View {
    let store: StoreOf<DetailFeature>

    var body: some View {
        if let issue = store.issue {
            Form {
                Section("Title") {
                    Text(issue.title)
                }

                Section("Detail") {
                    Text(issue.detail)
                }
            }
            .navigationTitle(issue.title)
            .navigationBarTitleDisplayMode(.large)
        } else {
            ContentUnavailableView("Issue Not Found", systemImage: "exclamationmark.triangle")
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(store: Store(
            initialState: DetailFeature.State(issueID: UUID(10)),
            reducer: { DetailFeature() },
            withDependencies: { try! $0.bootstrapDatabase() }
        ))
    }
}
