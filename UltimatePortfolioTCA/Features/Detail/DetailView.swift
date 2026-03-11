import ComposableArchitecture
import SwiftUI

@ViewAction(for: DetailFeature.self)
struct DetailView: View {
    @Bindable var store: StoreOf<DetailFeature>

    private var issue: Issue.Draft {
        if let issue = store.issue {
            return Issue.Draft(issue)
        }
        return store.draft
    }

    private var title: String {
        switch (store.isEditing, store.issue) {
        case (true, .some): "Edit Issue"
        case (true, .none): "New Issue"
        case (false, .some): "Details"
        case (false, .none): ""
        }
    }

    var body: some View {
        VStack {
            if store.issue != nil || store.isEditing {
                Form {
                    DetailTitle(text: store.isEditing ? $store.draft.title : .constant(issue.title), isEditing: store.isEditing)

                    DetailDescription(
                        text: store.isEditing ? $store.draft.detail : .constant(!issue.detail.isEmpty ? issue.detail : "No Description"),
                        isEditing: store.isEditing
                    )

                    DetailStatus(
                        priority: store.isEditing ? $store.draft.priority : .constant(issue.priority),
                        isCompleted: store.isEditing ? $store.draft.isCompleted : .constant(issue.isCompleted),
                        isEditing: store.isEditing
                    )

                    if !store.isEditing {
                        DetailDates(created: issue.created, modified: issue.modified)
                    }

                    DetailTags(
                        selectedTagIDs: $store.selectedTagIDs,
                        tagRows: store.tagRows,
                        isEditing: store.isEditing
                    ) {
                        send(.createTagButtonTapped)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No Issue Found", systemImage: "exclamationmark.magnifyingglass")
                } actions: {
                    Button("Create New Issue") { send(.createIssueButtonTapped) }
                }
            }
        }
        .animation(.default, value: store.isEditing)
        .navigationTitle(title)
        .toolbarTitleDisplayMode(.inline)
        .alert($store.scope(state: \.alert, action: \.alert))
        .toolbar {
            if store.isEditing {
                editIssueToolBarContent
            } else if let issueIsCompleted = store.issue?.isCompleted {
                viewIssueToolBarContent(issueIsCompleted: issueIsCompleted)
            }
        }
    }

    @ToolbarContentBuilder
    var editIssueToolBarContent: some ToolbarContent {
        // Only show delete when editing an existing issue
        if store.issue != nil {
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

    @ToolbarContentBuilder
    func viewIssueToolBarContent(issueIsCompleted: Bool) -> some ToolbarContent {
        ToolbarItem {
            Menu {
                Button {
                    UIPasteboard.general.string = issue.title
                } label: {
                    Label("Copy Issue Title", systemImage: "doc.on.doc")
                }

                Button {
                    send(.toggleIssueCompletedButtonTapped)
                } label: {
                    Label(
                        issueIsCompleted ? "Re-open Issue" : "Close Issue",
                        systemImage: "bubble.left.and.exclamationmark.bubble.right"
                    )
                }
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button {
                send(.editButtonTapped)
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
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

#Preview("No Issue Found") {
    withPreviewDependencies {
        NavigationStack {
            DetailView(store: Store(initialState: DetailFeature.State(issueID: UUID(-1))) {
                DetailFeature()
            })
        }
    }
}

#Preview("Create Mode") {
    withPreviewDependencies {
        NavigationStack {
            DetailView(store: Store(initialState: DetailFeature.State(
                issueID: UUID(-1),
                isEditing: true
            )) {
                DetailFeature()
            })
        }
    }
}
