import Dependencies
import Foundation

extension UUID {
    // MARK: - Tags

    /// "SwiftUI" tag — the most widely assigned tag (4 open + 1 completed issue).
    static let tagSwiftUI = UUID(1)

    /// "Networking" tag — assigned to the completed networking refactor and the push notification issue.
    static let tagNetworking = UUID(2)

    /// "Core Data" tag — exists but has no assigned issues (empty tag scenario).
    static let tagCoreData = UUID(3)

    /// "UI Design" tag — assigned to dark mode, onboarding, and push notification issues.
    static let tagUIDesign = UUID(4)

    /// "Bug" tag — assigned to the login layout fix and the iPad rotation crash.
    static let tagBug = UUID(5)

    /// "Accessibility & VoiceOver" tag — long tag name for testing chip layout wrapping.
    static let tagAccessibility = UUID(6)

    // MARK: - Issues

    /// "Fix login screen layout" — high priority, open, no modified date. Tags: SwiftUI, Bug.
    static let issueLoginLayout = UUID(10)

    /// "Add dark mode support" — medium priority, open, has modified date. Tags: SwiftUI, UI Design.
    static let issueDarkMode = UUID(11)

    /// "Refactor networking layer" — medium priority, completed. Tags: Networking.
    static let issueNetworkingRefactor = UUID(12)

    /// "Update onboarding flow" — low priority, open, no modified date. Tags: SwiftUI, UI Design.
    static let issueOnboarding = UUID(13)

    /// "Fix crash on iPad rotation" — high priority, completed, recently modified. Tags: SwiftUI, Bug.
    static let issueIPadCrash = UUID(14)

    /// "Audit VoiceOver labels…" — low priority, open, long title, empty detail, no tags.
    static let issueVoiceOverAudit = UUID(15)

    /// "Implement comprehensive push notification system…" — medium priority, open, long title and detail, 4 tags.
    /// Tags: SwiftUI, Networking, UI Design, Accessibility & VoiceOver.
    static let issuePushNotifications = UUID(16)
}
