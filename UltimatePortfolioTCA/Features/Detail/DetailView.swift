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
        switch (store.isEditing, store.issueID) {
        case (true, .some): "Edit Issue"
        case (true, .none): "New Issue"
        case (false, .some): "Details"
        case (false, .none): ""
        }
    }

    private var assignedTags: [Tag] {
        store.tagRows.filter(\.isAssigned).map(\.tag)
    }

    private var unassignedTags: [Tag] {
        store.tagRows.filter(\.isNotAssigned).map(\.tag)
    }

    var body: some View {
        VStack {
            if store.issue != nil || store.isEditing {
                Form {
                    // TODO: Extract
                    Section("Title") {
                        TextField(
                            "Title",
                            text: store.isEditing ? $store.draft.title : .constant(issue.title),
                            axis: .vertical
                        )
                        .disabled(!store.isEditing)
                        .accessibilityHint("editable", isEnabled: store.isEditing)
                    }

                    // TODO: Extract
                    Section("Description") {
                        TextField(
                            "Description",
                            text: store.isEditing
                                ? $store.draft.detail
                                : .constant(!issue.detail.isEmpty ? issue.detail : "No Description"),
                            axis: .vertical
                        )
                        .lineLimit(1...10)
                        .foregroundStyle(store.isEditing || !issue.detail.isEmpty ? .primary : .secondary)
                        .disabled(!store.isEditing)
                        .accessibilityHint("editable", isEnabled: store.isEditing)
                    }

                    // TODO: Extract
                    Section("Status") {
                        LabeledContent("Priority") {
                            HStack {
                                if !store.isEditing {
                                    PriorityIndicator(priority: issue.priority)
                                }
                                Picker(
                                    "Priority",
                                    selection: store.isEditing ? $store.draft.priority : .constant(issue.priority)
                                ) {
                                    ForEach(Issue.Priority.allCases) { priority in
                                        Text(priority.label).tag(priority)
                                    }
                                }
                                .labelsHidden()
                                .disabled(!store.isEditing)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Priority")
                        .accessibilityValue(issue.priority.label)
                        .accessibilityAddTraits(store.isEditing ? .isButton : [])

                        LabeledContent("Completed") {
                            Toggle("Completed", isOn: store.isEditing ? $store.draft.isCompleted : .constant(issue.isCompleted))
                                .labelsHidden()
                                .disabled(!store.isEditing)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Completed")
                        .accessibilityValue(issue.isCompleted ? "Yes" : "No")
                        .accessibilityAddTraits(store.isEditing ? .isToggle : [])
                    }

                    // TODO: Extract
                    if !store.isEditing {
                        Section("Dates") {
                            LabeledContent("Created", value: issue.created, format: .dateTime)

                            if let modified = issue.modified {
                                LabeledContent("Modified", value: modified, format: .dateTime)
                            }
                        }
                    }

                    // TODO: Extract
                    Section("Tags") {
                        FlowLayout {
                            if store.isEditing {
                                ForEach(assignedTags + unassignedTags) { tag in
                                    TagButton(tag: tag, isAssigned: store.selectedTagIDs.contains(tag.id)) {
                                        withAnimation {
                                            if store.selectedTagIDs.contains(tag.id) { store.selectedTagIDs.remove(tag.id) }
                                            else { store.selectedTagIDs.insert(tag.id) }
                                        }
                                    }
                                }

                                Button {
                                    send(.createTagButtonTapped)
                                } label: {
                                    Text("+ Add Tag")
                                        .chipStyle(isAssigned: false)
                                        .overlay { Capsule().strokeBorder(.secondary) }
                                        .accessibilityLabel("Add Tag")
                                }
                            } else {
                                if assignedTags.isEmpty {
                                    Text("No tags")
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(assignedTags) { tag in
                                        Text(tag.name)
                                            .chipStyle()
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No Issue Selected", systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("Create New Issue") { send(.createNewIssueButtonTapped) }
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

    private struct TagButton: View {
        let tag: Tag
        let isAssigned: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(tag.name)
                    .chipStyle(isAssigned: isAssigned)
                    .accessibilityAddTraits(isAssigned ? .isSelected : [])
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
