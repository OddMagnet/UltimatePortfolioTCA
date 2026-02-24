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
            DetailView(store: store.scope(state: \.detail, action: \.detail))
        }
        .alert(item: $store.tagDraft) {
            Text($0.name.isEmpty ? "New Tag" : "Rename Tag")
        } actions: { tagDraft in
            TextField("Tag name", text: tagDraft.name)
            Button("Save") { store.send(.tagAlertConfirmButtonTapped) }
            Button("Cancel") {}
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
