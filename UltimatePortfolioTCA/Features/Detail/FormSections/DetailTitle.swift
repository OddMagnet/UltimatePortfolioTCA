import SwiftUI

struct DetailTitle: View {
    @Binding var text: String
    let isEditing: Bool

    var body: some View {
        Section("Title") {
            TextField("Title", text: $text, axis: .vertical)
                .disabled(!isEditing)
                .accessibilityHint("editable", isEnabled: isEditing)
        }
    }
}
