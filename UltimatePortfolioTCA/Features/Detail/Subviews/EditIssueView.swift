import SwiftUI

/// Editable form for modifying an issue's title, description, status, and tag assignments.
struct EditIssueView: View {
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

            Section("Tags") {
                FlowLayout {
                    ForEach(assignedTags + unassignedTags) { tag in
                        Button {
                            withAnimation {
                                if selectedTagIDs.contains(tag.id) { selectedTagIDs.remove(tag.id) }
                                else { selectedTagIDs.insert(tag.id) }
                            }
                        } label: {
                            TagChip(
                                name: tag.name,
                                isAssigned: selectedTagIDs.contains(tag.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
