import ComposableArchitecture
import SwiftUI

struct DetailView: View {
    let store: StoreOf<DetailFeature>

    var body: some View {
        Group {
            if let issue = store.issue {
                Form {
                    Section("Title") {
                        Text(issue.title)
                    }

                    Section("Detail") {
                        Text(issue.detail)
                    }
                }
            } else {
                ContentUnavailableView("Issue Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Details")
        .toolbarTitleDisplayMode(.inlineLarge)
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
