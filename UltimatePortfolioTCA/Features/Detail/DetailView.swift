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
                        FlowLayout {
                            ForEach(assignedTags) { tag in
                                TagChip(name: tag.name)
                            }
                        }
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
}

// MARK: - Tag Chip

private struct TagChip: View {
    let name: String
    var isAssigned: Bool = true

    var body: some View {
        Text(name)
            .font(.subheadline)
            .bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isAssigned ? .white : .secondary)
            .background(isAssigned ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: .capsule)
            .geometryGroup()
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalSize: CGSize = .zero

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
            totalSize.width = max(totalSize.width, x - horizontalSpacing)
            totalSize.height = max(totalSize.height, y + rowHeight)
        }

        return ArrangeResult(size: totalSize, positions: positions)
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
