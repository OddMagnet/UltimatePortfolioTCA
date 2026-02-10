import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

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
            if let detailStore = store.scope(state: \.detail, action: \.detail) {
                DetailView(store: detailStore)
            } else {
                ContentUnavailableView("Select an Issue", systemImage: "doc.text")
            }
        }
    }
}

#Preview {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State()) {
            AppFeature()
        })
    }
}
