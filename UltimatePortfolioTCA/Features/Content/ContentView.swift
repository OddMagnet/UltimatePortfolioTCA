import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @Bindable var store: StoreOf<ContentFeature>

    var body: some View {
        List(selection: $store.selectedIssue) {
            // Issue rows will be added when DB queries are wired
        }
        .navigationTitle(store.filter.title)
        .overlay {
            ContentUnavailableView("No Issues", systemImage: "tray")
        }
    }
}

#Preview {
    ContentView(
        store: Store(initialState: ContentFeature.State(filter: .all)) {
            ContentFeature()
        }
    )
}
