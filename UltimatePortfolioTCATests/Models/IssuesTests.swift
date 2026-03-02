import Testing
@testable import UltimatePortfolioTCA

@Test func IssueFilter() {
    let testTag = Tag(id: .tagSwiftUI, name: "SwiftUI")
    // Test toggle
    #expect(IssueFilter.open.hasShowCompletedToggle == false)
    #expect(IssueFilter.completed.hasShowCompletedToggle == false)
    #expect(IssueFilter.recent.hasShowCompletedToggle == true)
    #expect(IssueFilter.tag(testTag).hasShowCompletedToggle == true)
    // Test `showsCompletedIssues`
    // open always hides
    #expect(IssueFilter.open.showsCompletedIssues(with: true) == false)
    #expect(IssueFilter.open.showsCompletedIssues(with: false) == false)
    // completed always shows
    #expect(IssueFilter.completed.showsCompletedIssues(with: true) == true)
    #expect(IssueFilter.completed.showsCompletedIssues(with: false) == true)
    // recent and tag respects pref
    #expect(IssueFilter.recent.showsCompletedIssues(with: true) == true)
    #expect(IssueFilter.recent.showsCompletedIssues(with: false) == false)
    #expect(IssueFilter.tag(testTag).showsCompletedIssues(with: true) == true)
    #expect(IssueFilter.tag(testTag).showsCompletedIssues(with: false) == false)
}
