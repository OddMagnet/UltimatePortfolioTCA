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
                            .contextMenu {
                                Button {
                                    send(.renameTagSwiped(row.tag))
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    send(.deleteTagsSwiped([row.tag.id]))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteTagsForOffsets)
                }
            }
        }
        .navigationTitle("Filters")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) {
                    send(.createTagButtonTapped)
                } label: {
                    Label("Add Tag", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    send(.showAwardsButtonTapped)
                } label: {
                    Label("Show awards", systemImage: "rosette")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                SortMenu(currentOrder: store.sortOrder) { order in
                    send(.sortOrderSelected(order))
                }
            }
        }
        .onChange(of: store.showCompleted) {
            send(.showCompletedToggled)
        }
    }

    private func deleteTagsForOffsets(_ offsets: IndexSet) {
        let tagIDs = offsets.map { store.tagRows[$0].id }
        send(.deleteTagsSwiped(tagIDs))
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
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(filter.title)
            .accessibilityHint("\(count) issues", isEnabled: count > 0)
    }
}

#Preview {
    withPreviewDependencies {
        NavigationStack {
            SidebarView(store: Store(initialState: SidebarFeature.State()) {
                SidebarFeature()
            })
        }
    }
}
