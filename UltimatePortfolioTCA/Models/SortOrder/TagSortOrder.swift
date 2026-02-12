/// Sort order options for tags in the sidebar.
/// The ordering logic lives in `extension Select where From == Tag` in `Tag.swift`.
enum TagSortOrder: String, SortOrderProtocol {
    case name, issueCount
    var label: String {
        switch self {
        case .name: "Name"
        case .issueCount: "Issue Count"
        }
    }
    var defaultAscending: Bool {
        switch self {
        case .name: true
        case .issueCount: false
        }
    }
    var id: Self { self }
}
