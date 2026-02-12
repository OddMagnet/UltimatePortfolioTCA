import Foundation
import StructuredQueries

@Table struct Tag: Hashable, Identifiable {
    typealias ID = UUID

    let id: ID
    var name = ""
}

/// Ordering extension for tag queries after `leftJoin(IssueTag).leftJoin(Issue)`.
/// The `(IssueTag?, Issue?)` constraint matches the optional types produced by `leftJoin`.
extension Select where From == Tag, Joins == (IssueTag?, Issue?) {
    /// Appends an ORDER BY clause for the given ``TagSortOrder``.
    ///
    /// - `name`: sorts alphabetically by tag name
    /// - `issueCount`: sorts by the count of visible (non-completed, unless `showCompleted`) issues
    ///
    /// The `showCompleted` flag is bridged into SQL via `Bool.or()` so that when `true`,
    /// all issues count; when `false`, only non-completed issues count.
    func order(by sortOrder: TagSortOrder, ascending: Bool, showCompleted: Bool) -> Self {
        self.order { tags, _, issues in
            let isVisible = showCompleted.or(issues.isCompleted.neq(true))
            let visibleCount = issues.count(distinct: true, filter: isVisible)
            switch (sortOrder, ascending) {
            case (.name, true): tags.name.asc()
            case (.name, false): tags.name.desc()
            case (.issueCount, true): visibleCount.asc()
            case (.issueCount, false): visibleCount.desc()
            }
        }
    }
}
