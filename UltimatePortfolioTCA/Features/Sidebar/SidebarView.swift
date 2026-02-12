import ComposableArchitecture
import SwiftUI

@ViewAction(for: SidebarFeature.self)
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
                        .onDelete { send(.deleteTagsSwiped(offsets: $0)) }
                }
            }
        }
        .navigationTitle("Filters")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            Menu {
                ForEach(TagSortOrder.allCases) { order in
                    Button {
                        send(.didSelectOrder(order))
                    } label: {
                        if order == store.sortOrder {
                            Label(order.label, systemImage: store.sortAscending ? "chevron.up" : "chevron.down")
                        } else {
                            Text(order.label)
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
        .onChange(of: store.showCompleted) {
            send(.showCompletedChanged)
        }
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
        self.count = row.issueCount
    }

    var body: some View {
        Label(filter.title, systemImage: filter.systemImage)
            .badge(count)
            .tag(filter)
    }
}

#Preview {
    NavigationStack {
        SidebarView(store: Store(
            initialState: SidebarFeature.State(),
            reducer: { SidebarFeature() },
            withDependencies: { try! $0.bootstrapDatabase() }
        ))
    }
}
