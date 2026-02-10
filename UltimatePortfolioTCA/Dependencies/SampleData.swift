import Dependencies
import Foundation
import SQLiteData

extension Database {
    func seedSampleData() throws {
        // Clean up old samples
        try Issue.delete().execute(self)
        try Tag.delete().execute(self)
        try IssueTag.delete().execute(self)

        // Add new ones
        try seed {
            Tag(id: UUID(1), name: "SwiftUI")
            Tag(id: UUID(2), name: "Networking")
            Tag(id: UUID(3), name: "Core Data")
            Tag(id: UUID(4), name: "UI Design")
            Tag(id: UUID(5), name: "Bug")

            Issue(id: UUID(10), title: "Fix login screen layout", detail: "The login button overlaps with the text field on smaller devices", priority: .high, modified: nil)
            Issue(id: UUID(11), title: "Add dark mode support", detail: "Implement dark mode across all screens using asset catalogs", priority: .medium, modified: nil)
            Issue(id: UUID(12), title: "Refactor networking layer", detail: "Replace URLSession calls with async/await", priority: .medium, completed: true, modified: nil)
            Issue(id: UUID(13), title: "Update onboarding flow", detail: "Add new welcome screens with animations", priority: .low, modified: nil)
            Issue(id: UUID(14), title: "Fix crash on iPad rotation", detail: "App crashes when rotating from portrait to landscape on iPad Pro", priority: .high, completed: true, modified: nil)

            IssueTag.Draft(issueID: UUID(10), tagID: UUID(1))
            IssueTag.Draft(issueID: UUID(10), tagID: UUID(5))
            IssueTag.Draft(issueID: UUID(11), tagID: UUID(1))
            IssueTag.Draft(issueID: UUID(11), tagID: UUID(4))
            IssueTag.Draft(issueID: UUID(12), tagID: UUID(2))
            IssueTag.Draft(issueID: UUID(13), tagID: UUID(1))
            IssueTag.Draft(issueID: UUID(13), tagID: UUID(4))
            IssueTag.Draft(issueID: UUID(14), tagID: UUID(1))
            IssueTag.Draft(issueID: UUID(14), tagID: UUID(5))
        }
    }
}
