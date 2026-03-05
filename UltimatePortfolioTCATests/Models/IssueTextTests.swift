import Foundation
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    struct IssueTextTests {
        // MARK: - sanitize(query:)

        @Test func sanitizeNormalTerms() {
            #expect(IssueText.sanitize(query: "login screen") == "\"login\"* \"screen\"*")
        }

        @Test func sanitizeSingleTerm() {
            #expect(IssueText.sanitize(query: "dark") == "\"dark\"*")
        }

        @Test func sanitizeStripsSpecialCharacters() {
            #expect(IssueText.sanitize(query: "hello*world") == "\"helloworld\"*")
            #expect(IssueText.sanitize(query: "foo+bar-baz") == "\"foobarbaz\"*")
            #expect(IssueText.sanitize(query: "\"quoted\"") == "\"quoted\"*")
            #expect(IssueText.sanitize(query: "test(1)") == "\"test1\"*")
        }

        @Test func sanitizeReturnsNilForEmptyInput() {
            #expect(IssueText.sanitize(query: "") == nil)
        }

        @Test func sanitizeReturnsNilForWhitespaceOnly() {
            #expect(IssueText.sanitize(query: "   ") == nil)
        }

        @Test func sanitizeReturnsNilForOnlySpecialCharacters() {
            #expect(IssueText.sanitize(query: "*+-()") == nil)
        }

        @Test func sanitizeTrimsExtraSpaces() {
            #expect(IssueText.sanitize(query: "  fix   login  ") == "\"fix\"* \"login\"*")
        }

        @Test func sanitizeHandlesMixedInput() {
            #expect(IssueText.sanitize(query: "crash (iPad)") == "\"crash\"* \"iPad\"*")
        }
    }
}
