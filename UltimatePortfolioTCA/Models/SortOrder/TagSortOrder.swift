/// Sort order options for tags in the sidebar.
/// The ordering logic lives in `extension Select where From == Tag` in `Tag.swift`.
struct TagSortOrder: SortOrderProtocol {
    enum Field: CaseIterable, Codable { case name, issueCount }

    var field: Field
    var isAscending: Bool

    init(_ field: Field) {
        self.field = field
        isAscending = switch field {
        case .name: true
        case .issueCount: false
        }
    }

    var label: String {
        switch field {
        case .name: "Name"
        case .issueCount: "Issue Count"
        }
    }
}
