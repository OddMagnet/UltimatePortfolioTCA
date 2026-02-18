import SwiftUI

/// A capsule-shaped chip for displaying a tag name.
/// Assigned tags use a solid tint background with white text;
/// unassigned tags use a tertiary fill with secondary text.
struct TagChip: View {
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
