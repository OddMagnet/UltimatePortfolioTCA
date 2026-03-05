import Dependencies
import Foundation
import Testing
@testable import UltimatePortfolioTCA

extension BaseTestSuite {
    struct SearchTokenTests {
        // MARK: - Token identity

        @Test func tagTokenIDsAreUnique() {
            let tag1 = Tag(id: UUID(1), name: "SwiftUI")
            let tag2 = Tag(id: UUID(2), name: "Bug")
            let token1 = SearchToken.tag(tag1)
            let token2 = SearchToken.tag(tag2)
            #expect(token1.id != token2.id)
        }

        @Test func priorityTokenIDsAreUnique() {
            let low = SearchToken.priority(.low)
            let medium = SearchToken.priority(.medium)
            let high = SearchToken.priority(.high)
            #expect(Set([low.id, medium.id, high.id]).count == 3)
        }

        @Test func statusTokenIDsAreUnique() {
            let open = SearchToken.status(.open)
            let completed = SearchToken.status(.completed)
            #expect(open.id != completed.id)
        }

        @Test func tokenIDsAreUniqueAcrossCategories() {
            let tag = SearchToken.tag(Tag(id: UUID(0), name: "Test"))
            let priority = SearchToken.priority(.low)
            let status = SearchToken.status(.open)
            let ids = [tag.id, priority.id, status.id]
            #expect(Set(ids).count == 3)
        }

        // MARK: - Labels

        @Test func tagTokenUsesTagName() {
            let tag = Tag(id: UUID(1), name: "SwiftUI")
            #expect(SearchToken.tag(tag).label == "SwiftUI")
        }

        @Test func priorityTokenUsesLabel() {
            #expect(SearchToken.priority(.high).label == "High")
            #expect(SearchToken.priority(.medium).label == "Medium")
            #expect(SearchToken.priority(.low).label == "Low")
        }

        @Test func statusTokenUsesLabel() {
            #expect(SearchToken.status(.open).label == "Open")
            #expect(SearchToken.status(.completed).label == "Completed")
        }

        // MARK: - System images

        @Test func systemImages() {
            #expect(SearchToken.tag(Tag(id: UUID(0), name: "")).systemImage == "tag")
            #expect(SearchToken.priority(.low).systemImage == "flag")
            #expect(SearchToken.status(.open).systemImage == "circle")
            #expect(SearchToken.status(.completed).systemImage == "checkmark.circle")
        }
    }
}
