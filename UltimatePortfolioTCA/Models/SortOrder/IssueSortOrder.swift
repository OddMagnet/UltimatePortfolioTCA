import SwiftUI

/// Sort order options for issues in the content list.
/// The ordering logic lives in `extension Select where From == Issue` in `Issue.swift`.
struct IssueSortOrder: SortOrderProtocol {
    enum Field: CaseIterable, Codable { case date, priority, title }

    var field: Field
    var isAscending: Bool

    init(_ field: Field) {
        self.field = field
        isAscending = switch field {
        case .date, .priority: false
        case .title: true
        }
    }

    var label: LocalizedStringKey {
        switch field {
        case .date: "Date"
        case .priority: "Priority"
        case .title: "Title"
        }
    }
}
