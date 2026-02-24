import SwiftUI

/// Applies capsule-shaped chip styling to any view.
/// Assigned style: white text on tint background.
/// Unassigned style: secondary text on tertiary fill.
struct ChipStyle: ViewModifier {
    var isAssigned: Bool = true

    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isAssigned ? .white : .secondary)
            .background {
                Capsule()
                    .fill(isAssigned ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary))
            }
            .geometryGroup()
    }
}

extension View {
    func chipStyle(isAssigned: Bool = true) -> some View {
        modifier(ChipStyle(isAssigned: isAssigned))
    }
}
