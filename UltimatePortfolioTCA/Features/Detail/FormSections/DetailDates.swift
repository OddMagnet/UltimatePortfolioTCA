import SwiftUI

struct DetailDates: View {
    let created: Date
    let modified: Date?

    var body: some View {
        Section("Dates") {
            LabeledContent("Created", value: created, format: .dateTime)
            if let modified {
                LabeledContent("Modified", value: modified, format: .dateTime)
            }
        }
    }
}
