import ComposableArchitecture
import SwiftUI

struct SidebarView: View {
    @Bindable var store: StoreOf<SidebarFeature>

    var body: some View {
        List(selection: $store.selectedFilter) {
            Section("Filters") {
                filterRow(.all)
                filterRow(.recent)
                filterRow(.completed)
            }

            Section("Tags") {
                Text("No tags yet")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Filters")
    }

    private func filterRow(_ filter: SidebarFeature.State.Filter) -> some View {
        Label(filter.title, systemImage: filter.systemImage)
            .tag(filter)
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(
            store: Store(initialState: SidebarFeature.State()) {
                SidebarFeature()
            }
        )
    } content: {
        Text("Content")
    } detail: {
        Text("Detail")
    }
}
