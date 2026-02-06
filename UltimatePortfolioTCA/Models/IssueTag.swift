import Foundation
import StructuredQueries

@Table struct IssueTag: Identifiable {
    typealias ID = UUID

    let id: ID
    var issueID: Issue.ID
    var tagID: Tag.ID
}
