import SwiftUI

struct DetailTags: View {
    @Binding var selectedTagIDs: Set<Tag.ID>
    let tagRows: [TagRow]
    let isEditing: Bool
    let onCreateTagButton: () -> Void

    private var assignedTags: [Tag] {
        tagRows.filter { selectedTagIDs.contains($0.tag.id) }.map(\.tag)
    }

    private var unassignedTags: [Tag] {
        tagRows.filter { !selectedTagIDs.contains($0.tag.id) }.map(\.tag)
    }

    var body: some View {
        Section("Tags") {
            FlowLayout {
                if isEditing {
                    ForEach(assignedTags + unassignedTags) { tag in
                        TagButton(tag: tag, isAssigned: selectedTagIDs.contains(tag.id)) {
                            withAnimation {
                                if selectedTagIDs.contains(tag.id) {
                                    selectedTagIDs.remove(tag.id)
                                } else {
                                    selectedTagIDs.insert(tag.id)
                                }
                            }
                        }
                    }

                    Button(action: onCreateTagButton) {
                        HStack(spacing: 0) {
                            Text("+ ")
                            Text("Add Tag")
                        }
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
