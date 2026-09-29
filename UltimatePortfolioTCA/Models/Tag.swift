import Foundation
import StructuredQueries

@Table struct Tag: Hashable, Identifiable {
    typealias ID = UUID

    let id: ID
    var name = ""
}

extension Tag.Draft: Equatable {}

/// Ordering extension for tag queries after `leftJoin(IssueTag).leftJoin(Issue)`.
/// The `(IssueTag?, Issue?)` constraint matches the optional types produced by `leftJoin`.
extension Select where From == Tag, Joins == (IssueTag?, Issue?) {
    /// Appends an ORDER BY clause for the given ``TagSortOrder`` field and direction.
    ///
    /// - `.name`: sorts alphabetically by tag name
    /// - `.issueCount`: sorts by the count of visible (non-completed, unless `showCompleted`) issues
    ///
    /// The `showCompleted` flag is bridged into SQL via `Bool.or()` so that when `true`,
    /// all issues count; when `false`, only non-completed issues count.
    func order(by sortOrder: TagSortOrder, showCompleted: Bool) -> Self {
        order { tags, _, issues in
            let isVisible = showCompleted.or(issues.isCompleted.neq(true))
            let visibleCount = issues.count(distinct: true, filter: isVisible)
            switch sortOrder.field {
            case .name:
                if sortOrder.isAscending {
                    tags.name.asc()
                } else {
                    tags.name.desc()
                }
            case .issueCount:
                if sortOrder.isAscending {
                    visibleCount.asc()
                } else {
                    visibleCount.desc()
                }
            }
        }
    }
}
