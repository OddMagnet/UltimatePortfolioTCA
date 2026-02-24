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
                    Button(role: .confirm) {
                        send(.createTagButtonTapped)
                    } label: {
                        Label("Add Tag", systemImage: "plus")
                    }
                } else {
                    ForEach(store.tagRows) { row in
                        FilterRow(row: row)
                            .swipeActions(edge: .leading) {
                                Button {
                                    send(.renameTagSwiped(row.tag))
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    send(.deleteTagSwiped(row.tag))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Filters")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SortMenu(currentOrder: store.sortOrder) { order in
                    send(.sortOrderSelected(order))
                } extraActions: {
                    Button(role: .confirm) {
                        send(.createTagButtonTapped)
                    } label: {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
            }
        }
        .onChange(of: store.showCompleted) {
            send(.showCompletedToggled)
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
        filter = .tag(row.tag)
        count = row.issueCount
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
