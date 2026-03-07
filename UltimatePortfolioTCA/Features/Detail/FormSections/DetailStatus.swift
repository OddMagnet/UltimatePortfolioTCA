import SwiftUI

struct DetailStatus: View {
    @Binding var priority: Issue.Priority
    @Binding var isCompleted: Bool
    let isEditing: Bool

    var body: some View {
        Section("Status") {
            LabeledContent("Priority") {
                HStack {
                    if !isEditing { PriorityIndicator(priority: priority) }
                    Picker("Priority", selection: $priority) {
                        ForEach(Issue.Priority.allCases) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }
                    .labelsHidden()
                    .disabled(!isEditing)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Priority")
            .accessibilityValue(priority.label)
            .accessibilityAddTraits(isEditing ? .isButton : [])

            LabeledContent("Completed") {
                Toggle("Completed", isOn: $isCompleted)
                    .labelsHidden()
                    .disabled(!isEditing)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Completed")
            .accessibilityValue(isCompleted ? "Yes" : "No")
            .accessibilityAddTraits(isEditing ? .isToggle : [])
        }
    }
}
