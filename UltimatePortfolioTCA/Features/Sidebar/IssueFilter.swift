import SQLiteData
import SwiftUI

/// Filter criteria for issues in the sidebar and content list.
///
/// Smart filters (`.open`, `.completed`, `.recent`) appear in the sidebar's "Smart Filters" section.
/// `.tag` filters by a specific tag via a subquery on ``IssueTag``.
/// Use ``smartFilters`` to get the array excluding `.tag`.
enum IssueFilter: Hashable, Identifiable {
    var id: Self { self }

    case open
    case completed
    case recent
    case tag(Tag)

    static var smartFilters: [Self] {
        [.open, .completed, .recent]
    }

    var systemImage: String {
        switch self {
        case .open: "tray"
        case .completed: "checkmark"
        case .recent: "clock"
        case .tag: "tag"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .open: "Open"
        case .completed: "Completed"
        case .recent: "Recent"
        case let .tag(tag): "\(tag.name)"
        }
    }

    var hasShowCompletedToggle: Bool {
        switch self {
        case .open, .completed:
            false
        case .recent, .tag:
            true
        }
    }

    func showsCompletedIssues(with toggle: Bool) -> Bool {
        switch self {
        case .open: false
        case .completed: true
        case .recent, .tag:
            toggle
        }
    }
}
