import SQLiteData

enum IssueFilter: Hashable, Identifiable {
    var id: Self { self }

    case all
    case completed
    case recent
    case tag(Tag)

    static var smartFilters: [Self] {
        [.all, .completed, .recent]
    }

    static var smartFilterCounts: SmartFilterCounts {
        SmartFilterCounts()
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

extension IssueFilter {
    struct SmartFilterCounts: FetchKeyRequest {
        struct Value {
            var all = 0
            var completed = 0
            var recent = 0

            subscript(filter: IssueFilter) -> Int {
                switch filter {
                case .all: all
                case .completed: completed
                case .recent: recent
                case .tag: 0
                }
            }
        }

        func fetch(_ db: Database) throws -> Value {
            try Value(
                all: Issue.fetchCount(db),
                completed: Issue.where(\.completed).fetchCount(db),
                recent: Issue.where(\.isRecent).fetchCount(db)
            )
        }
    }
}
