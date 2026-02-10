import Foundation
import StructuredQueries
import SwiftUI

@Table struct Issue: Hashable, Identifiable {
    enum Priority: Int, QueryBindable {
        case low = 0
        case medium = 1
        case high = 2
    }

    typealias ID = UUID

    let id: ID
    var title = ""
    var detail = ""
    var priority: Priority?
    var completed = false
    var created: Date = Date()
    let modified: Date?
}

extension Issue {
    var priorityColor: Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .green
        case nil: .gray
        }
    }
}
