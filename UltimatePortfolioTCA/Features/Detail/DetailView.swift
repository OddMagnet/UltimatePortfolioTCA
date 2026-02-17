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

    // MARK: - View Mode

    private struct IssueView: View {
        let issue: Issue
        let assignedTags: [Tag]

        var body: some View {
            Form {
                Section("Title") {
                    Text(issue.title)
                }

                Section("Description") {
                    if issue.detail.isEmpty {
                        Text("No description")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(issue.detail)
                    }
                }

                Section("Status") {
                    LabeledContent("Priority") {
                        HStack {
                            Circle()
                                .fill(issue.priorityColor)
                                .frame(width: 10, height: 10)
                            Text(issue.priority.label)
                        }
                    }

                    LabeledContent("Completed") {
                        Image(systemName: issue.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(issue.isCompleted ? .green : .secondary)
                    }
                }

                Section("Dates") {
                    LabeledContent("Created", value: issue.created, format: .dateTime)

                    if let modified = issue.modified {
                        LabeledContent("Modified", value: modified, format: .dateTime)
                    }
                }

                Section("Tags") {
                    if assignedTags.isEmpty {
                        Text("No tags")
                            .foregroundStyle(.secondary)
                    } else {
                        // TODO: instead of a list, maybe show them in a more tag-like fashion?
                        Text(assignedTags.map(\.name).joined(separator: ", "))
                    }
                }
            }
        }
    }

    // MARK: - Edit Mode

    private struct EditIssueView: View {
        @Binding var draft: Issue.Draft
        @Binding var selectedTagIDs: Set<Tag.ID>
        let tags: [Tag]

        var assignedTags: [Tag] {
            tags.filter { selectedTagIDs.contains($0.id) }
        }
        var unassignedTags: [Tag] {
            tags.filter { !selectedTagIDs.contains($0.id) }
        }

        var body: some View {
            Form {
                Section("Title") {
                    TextField("Title", text: $draft.title)
                }

                Section("Description") {
                    TextField("Description", text: $draft.detail, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section("Status") {
                    Picker("Priority", selection: $draft.priority) {
                        ForEach(Issue.Priority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }

                    Toggle("Completed", isOn: $draft.isCompleted)
                }

                // TODO: Tags would look better in a scrollable horizontal stack
                // Tapping a tag would toggle it, so it would jump between lists
                // TODO: Animation for tag moving between lists
                if !assignedTags.isEmpty {
                    Section("Assigned Tags") {
                        ForEach(assignedTags) { tag in
                            Button {
                                selectedTagIDs.remove(tag.id)
                            } label: {
                                Label(tag.name, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }

                if !unassignedTags.isEmpty {
                    Section("Other Tags") {
                        ForEach(unassignedTags) { tag in
                            Button {
                                selectedTagIDs.insert(tag.id)
                            } label: {
                                Label(tag.name, systemImage: "circle")
                                    .foregroundStyle(.primary)
                            }
                        }
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
