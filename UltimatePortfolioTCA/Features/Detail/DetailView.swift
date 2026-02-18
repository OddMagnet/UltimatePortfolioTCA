import ComposableArchitecture
import SwiftUI

@ViewAction(for: DetailFeature.self)
struct DetailView: View {
    @Bindable var store: StoreOf<DetailFeature>

    var body: some View {
        Group {
            if store.isEditing {
                EditIssueView(
                    draft: $store.draft,
                    selectedTagIDs: $store.selectedTagIDs,
                    tags: store.tagRows.map(\.tag)
                )
                .alert($store.scope(state: \.alert, action: \.alert))
                .navigationTitle("Edit Issue")
            } else if let issue = store.issue {
                IssueView(
                    issue: issue,
                    assignedTags: store.tagRows.filter(\.isAssigned).map(\.tag)
                )
                .navigationTitle("Details")
            } else {
                ContentUnavailableView("Issue Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            if store.isEditing {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        send(.deleteButtonTapped)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        send(.cancelEditButtonTapped)
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        send(.saveButtonTapped)
                    } label: {
                        Label("Save", systemImage: "checkmark.circle")
                    }
                }
            } else if store.issue != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        send(.editButtonTapped)
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(store: Store(
            initialState: DetailFeature.State(issueID: UUID(10)),
            reducer: { DetailFeature() },
            withDependencies: { try! $0.bootstrapDatabase() }
        ))
    }
}
