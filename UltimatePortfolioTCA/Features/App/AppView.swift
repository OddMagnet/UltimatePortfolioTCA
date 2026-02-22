import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
        } content: {
            if let contentStore = store.scope(state: \.content, action: \.content) {
                ContentView(store: contentStore)
            } else {
                ContentUnavailableView("Select a Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        } detail: {
            DetailView(store: store.scope(state: \.detail, action: \.detail))
        }
    }
}

#Preview {
    AppView(store: Store(
        initialState: AppFeature.State(),
        reducer: { AppFeature() },
        withDependencies: { try! $0.bootstrapDatabase() }
    ))
}
