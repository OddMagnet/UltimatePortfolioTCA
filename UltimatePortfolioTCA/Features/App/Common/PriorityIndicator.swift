import SwiftUI

/// A small colored circle indicating an issue's priority level.
struct PriorityIndicator: View {
    let priority: Issue.Priority

    var body: some View {
        Circle()
            .fill(priority.color)
            .frame(width: 10, height: 10)
            .accessibilityLabel("Priority: \(priority.label)")
    }
}
