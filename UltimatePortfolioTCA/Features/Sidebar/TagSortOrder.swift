enum TagSortOrder: String, CaseIterable, Identifiable {
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
