import SwiftUI

struct DetailDescription: View {
    @Binding var text: String
    let isEditing: Bool

    var body: some View {
        Section("Description") {
            TextField("Description", text: $text, axis: .vertical)
                .lineLimit(1...10)
                .foregroundStyle(isEditing || !text.isEmpty ? .primary : .secondary)
                .disabled(!isEditing)
                .accessibilityHint("editable", isEnabled: isEditing)
        }
    }
}

struct EmptyDetailDescription: View {
    var body: some View {
        Section("Description") {
            Text("No Description")
                .lineLimit(1...10)
                .foregroundStyle(.secondary)
                .disabled(true)
        }
    }
}
