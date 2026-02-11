import Dependencies
import Foundation
import SQLiteData

extension DatabaseWriter {
    func seedSampleData() throws {
        // Clean up old samples
        try write { db in
            try Issue.delete().execute(db)
            try Tag.delete().execute(db)
            try IssueTag.delete().execute(db)
            
            @Dependency(\.date.now) var now
            func daysAgo(_ days: Int) -> Date {
                now.addingTimeInterval(Double(-days) * 86400)
            }
            
            // Add new ones
            try db.seed {
                Tag(id: UUID(1), name: "SwiftUI")
                Tag(id: UUID(2), name: "Networking")
                Tag(id: UUID(3), name: "Core Data")
                Tag(id: UUID(4), name: "UI Design")
                Tag(id: UUID(5), name: "Bug")
                
                Issue(id: UUID(10), title: "Fix login screen layout", detail: "The login button overlaps with the text field on smaller devices", priority: .high, created: daysAgo(2), modified: nil)
                Issue(id: UUID(11), title: "Add dark mode support", detail: "Implement dark mode across all screens using asset catalogs", priority: .medium, created: daysAgo(14), modified: daysAgo(3))
                Issue(id: UUID(12), title: "Refactor networking layer", detail: "Replace URLSession calls with async/await", priority: .medium, isCompleted: true, created: daysAgo(30), modified: daysAgo(20))
                Issue(id: UUID(13), title: "Update onboarding flow", detail: "Add new welcome screens with animations", priority: .low, created: daysAgo(10), modified: nil)
                Issue(id: UUID(14), title: "Fix crash on iPad rotation", detail: "App crashes when rotating from portrait to landscape on iPad Pro", priority: .high, isCompleted: true, created: daysAgo(21), modified: daysAgo(1))
                
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
}
