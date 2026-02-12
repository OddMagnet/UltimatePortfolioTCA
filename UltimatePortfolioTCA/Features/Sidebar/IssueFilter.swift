import SQLiteData

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

    var title: String {
        switch self {
        case .open: "Open"
        case .completed: "Completed"
        case .recent: "Recent"
        case let .tag(tag): tag.name
        }
    }
}
