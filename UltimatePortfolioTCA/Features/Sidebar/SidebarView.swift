import ComposableArchitecture
import SwiftUI

struct SidebarView: View {
    @Bindable var store: StoreOf<SidebarFeature>

    var body: some View {
        List(selection: $store.selectedFilter) {
            Section("Smart Filters") {
                ForEach(IssueFilter.smartFilters) { filter in
                    FilterRow(filter: filter, count: store.smartFilterCounts[filter])
                }
            }

            Section("Tags") {
                if store.tagRows.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.tagRows, content: FilterRow.init)
                        .onDelete { store.send(.deleteTagsSwiped(offsets: $0)) }
                }
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct FilterRow: View {
    let filter: IssueFilter
    let count: Int

    init(filter: IssueFilter, count: Int) {
        self.filter = filter
        self.count = count
    }

    init(row: TagWithCount) {
        self.filter = .tag(row.tag)
        self.count = row.activeIssueCount
    }

    var body: some View {
        Label(filter.title, systemImage: filter.systemImage)
            .badge(count)
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
