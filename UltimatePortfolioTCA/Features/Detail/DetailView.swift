import ComposableArchitecture
import SwiftUI

@ViewAction(for: DetailFeature.self)
struct DetailView: View {
    @Bindable var store: StoreOf<DetailFeature>
    var title: String {
        switch (store.isEditing, store.issueID) {
        case (true, .some): "Edit Issue"
        case (true, .none): "New Issue"
        case (false, .some): "Details"
        case (false, .none): ""
        }
    }

    var body: some View {
        VStack {
            if store.isEditing {
                EditIssueView(
                    draft: $store.draft,
                    selectedTagIDs: $store.selectedTagIDs,
                    tags: store.tagRows.map(\.tag),
                    onCreateTag: { send(.createTagButtonTapped) }
                )
                .alert($store.scope(state: \.alert, action: \.alert))
            } else if let issue = store.issue {
                IssueView(
                    issue: issue,
                    assignedTags: store.tagRows.filter(\.isAssigned).map(\.tag)
                )
            } else {
                ContentUnavailableView {
                    Label("No Issue Selected", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Create New Issue") { send(.createNewIssueButtonTapped) }
                }
            }
        }
        .animation(.default, value: store.issueID)
        .animation(.default, value: store.isEditing)
        .navigationTitle(title)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            if store.isEditing {
                editIssueToolBarContent
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

    @ToolbarContentBuilder
    var editIssueToolBarContent: some ToolbarContent {
        // Only show delete when editing an issue
        if store.issueID != nil {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    send(.deleteButtonTapped)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
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
    }
}

#Preview("Issue Selected") {
    withPreviewDependencies {
        NavigationStack {
            DetailView(store: Store(initialState: DetailFeature.State(issueID: .issueLoginLayout)) {
                DetailFeature()
            })
        }
    }
}

#Preview("No Issue Selected") {
    withPreviewDependencies {
        NavigationStack {
            DetailView(store: Store(initialState: DetailFeature.State(issueID: nil)) {
                DetailFeature()
            })
        }
    }
}

#Preview("Create Mode") {
    withPreviewDependencies {
        NavigationStack {
            DetailView(store: Store(initialState: DetailFeature.State(
                issueID: nil,
                isEditing: true
            )) {
                DetailFeature()
            })
        }
    }
}
