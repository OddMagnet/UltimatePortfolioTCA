/// Sort order options for issues in the content list.
/// The ordering logic lives in `extension Select where From == Issue` in `Issue.swift`.
enum IssueSortOrder: String, SortOrderProtocol {
    case date, priority, title
    var label: String {
        switch self {
        case .date: "Date"
        case .priority: "Priority"
        case .title: "Title"
        }
    }
    var defaultAscending: Bool {
        switch self {
        case .date, .priority: false
        case .title: true
        }
    }
    var id: Self { self }
}
