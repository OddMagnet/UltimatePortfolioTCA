import Dependencies
import DependenciesTestSupport
import Foundation
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    @Test func compactRelative() {
        @Dependency(\.date.now) var now
        #expect(now.addingTimeInterval(-60 * 30).compactRelative(to: now) == "< 1 hour")
        #expect(now.addingTimeInterval(-60 * 60 * 2).compactRelative(to: now) == "> 2 hours")
        #expect(now.addingTimeInterval(-60 * 60 * 24 * 3).compactRelative(to: now) == "> 3 days")
        let thirtyThreeDaysAgo = now.addingTimeInterval(-60 * 60 * 24 * 33)
        #expect(thirtyThreeDaysAgo.compactRelative(to: now) == thirtyThreeDaysAgo.formatted(.dateTime.day().month()))
        #expect(now.addingTimeInterval(-60 * 60 * 24 * 380).compactRelative(to: now) == "> 1 year")
    }
}
