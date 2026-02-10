import ComposableArchitecture
import SwiftUI

struct SidebarView: View {
    @Bindable var store: StoreOf<SidebarFeature>

    var body: some View {
        List(selection: $store.selectedFilter) {
            Section("Smart Filters") {
                ForEach(IssueFilter.smartFilters) { filter in
                    FilterRow(filter: filter)
                }
            }

            Section("Tags") {
                if store.tagRows.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.tagRows) { row in
                        Label(row.tag.name, systemImage: "tag")
                            .badge(row.activeIssueCount)
                            .tag(IssueFilter.tag(row.tag))
                    }
                    .onDelete { store.send(.deleteTagsSwiped(offsets: $0)) }
                }
            }
        }
        .navigationTitle("Filters")
    }
}

struct FilterRow: View {
    let filter: IssueFilter

    var body: some View {
        Label(filter.title, systemImage: filter.systemImage)
            .tag(filter)
    }
}

#Preview {
    withPreviewDependencies {
        NavigationView {
            SidebarView(store: Store(initialState: SidebarFeature.State()) {
                SidebarFeature()
            })
        }
    }
}
