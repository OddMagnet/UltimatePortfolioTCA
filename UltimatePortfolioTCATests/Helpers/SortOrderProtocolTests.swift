import Testing
@testable import UltimatePortfolioTCA

@Test func SortOrderProtocol() {
    var order = IssueSortOrder(.priority)
    // same field → toggles
    order.apply(IssueSortOrder(.priority))
    #expect(order.isAscending == true)
    // different field → replaces with default
    order.apply(IssueSortOrder(.title))
    #expect(order.field == .title)
    #expect(order.isAscending == true) // title's default direction
}
