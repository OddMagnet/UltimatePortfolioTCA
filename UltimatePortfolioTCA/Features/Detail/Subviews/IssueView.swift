import SwiftUI

/// Read-only view displaying a single issue's details: title, description, status, dates, and tags.
struct IssueView: View {
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
                        PriorityIndicator(priority: issue.priority)
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
                            Text(tag.name)
                                .chipStyle()
                        }
                    }
                }
            }
        }
    }
}
