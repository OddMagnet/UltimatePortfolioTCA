enum IssueFilter: Hashable, Identifiable {
    var id: Self { self }

    case all
    case completed
    case recent
    case tag(Tag)

    static var smartFilters: [Self] {
        [.all, .completed, .recent]
    }

    var systemImage: String {
        switch self {
        case .all: "tray"
        case .completed: "checkmark"
        case .recent: "clock"
        case .tag: "tag"
        }
    }

    var title: String {
        switch self {
        case .all: "All Issues"
        case .completed: "Completed"
        case .recent: "Recent"
        case let .tag(tag): tag.name
        }
    }
}
