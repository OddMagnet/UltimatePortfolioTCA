import Foundation
import SQLiteData

extension DatabaseWriter {
    // swiftlint:disable:next function_body_length
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
                Tag(id: .tagSwiftUI, name: "SwiftUI")
                Tag(id: .tagNetworking, name: "Networking")
                Tag(id: .tagCoreData, name: "Core Data")
                Tag(id: .tagUIDesign, name: "UI Design")
                Tag(id: .tagBug, name: "Bug")
                Tag(id: .tagAccessibility, name: "Accessibility & VoiceOver")

                Issue(
                    id: .issueLoginLayout,
                    title: "Fix login screen layout",
                    detail: "The login button overlaps with the text field on smaller devices",
                    priority: .high,
                    created: daysAgo(2),
                    modified: nil
                )
                Issue(
                    id: .issueDarkMode,
                    title: "Add dark mode support",
                    detail: "Implement dark mode across all screens using asset catalogs",
                    priority: .medium,
                    created: daysAgo(14),
                    modified: daysAgo(3)
                )
                Issue(
                    id: .issueNetworkingRefactor,
                    title: "Refactor networking layer",
                    detail: "Replace URLSession calls with async/await",
                    priority: .medium,
                    isCompleted: true,
                    created: daysAgo(30),
                    modified: daysAgo(20)
                )
                Issue(
                    id: .issueOnboarding,
                    title: "Update onboarding flow",
                    detail: "Add new welcome screens with animations",
                    priority: .low,
                    created: daysAgo(10),
                    modified: nil
                )
                Issue(
                    id: .issueIPadCrash,
                    title: "Fix crash on iPad rotation",
                    detail: "App crashes when rotating from portrait to landscape on iPad Pro",
                    priority: .high,
                    isCompleted: true,
                    created: daysAgo(21),
                    modified: daysAgo(1)
                )
                Issue(
                    id: .issueVoiceOverAudit,
                    title: "Audit VoiceOver labels and traits across the entire application for WCAG 2.1 AA compliance",
                    priority: .low,
                    created: daysAgo(5),
                    modified: nil
                )
                Issue(
                    id: .issuePushNotifications,
                    title: "Implement comprehensive push notification system with background delivery and rich media attachments",
                    detail: """
                    We need a full push notification system that handles foreground, background, \
                    and terminated states. This should include support for rich media attachments \
                    (images, video thumbnails), notification actions (reply, mark as read, snooze), \
                    and a notification service extension for decrypting end-to-end encrypted payloads. \
                    The system should also integrate with the existing badge count logic and group \
                    notifications by conversation thread using the thread-id field.
                    """,
                    priority: .medium,
                    created: daysAgo(8),
                    modified: daysAgo(4)
                )

                IssueTag.Draft(issueID: .issueLoginLayout, tagID: .tagSwiftUI)
                IssueTag.Draft(issueID: .issueLoginLayout, tagID: .tagBug)
                IssueTag.Draft(issueID: .issueDarkMode, tagID: .tagSwiftUI)
                IssueTag.Draft(issueID: .issueDarkMode, tagID: .tagUIDesign)
                IssueTag.Draft(issueID: .issueNetworkingRefactor, tagID: .tagNetworking)
                IssueTag.Draft(issueID: .issueOnboarding, tagID: .tagSwiftUI)
                IssueTag.Draft(issueID: .issueOnboarding, tagID: .tagUIDesign)
                IssueTag.Draft(issueID: .issueIPadCrash, tagID: .tagSwiftUI)
                IssueTag.Draft(issueID: .issueIPadCrash, tagID: .tagBug)
                // .issueVoiceOverAudit intentionally has no tags
                IssueTag.Draft(issueID: .issuePushNotifications, tagID: .tagSwiftUI)
                IssueTag.Draft(issueID: .issuePushNotifications, tagID: .tagNetworking)
                IssueTag.Draft(issueID: .issuePushNotifications, tagID: .tagUIDesign)
                IssueTag.Draft(issueID: .issuePushNotifications, tagID: .tagAccessibility)
            }
        }
    }
}
