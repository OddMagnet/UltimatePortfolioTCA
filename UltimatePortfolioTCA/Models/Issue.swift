import Foundation
import StructuredQueries
import SwiftUI

@Table struct Issue: Hashable, Identifiable {
    enum Priority: Int, QueryBindable {
        case low = 0
        case medium = 1
        case high = 2

        var label: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            }
        }
    }

    typealias ID = UUID

    let id: ID
    var title = ""
    var detail = ""
    var priority: Priority?
    var isCompleted = false
    var created: Date = Date()
    /// Automatically updated by a temporary trigger on issue updates. Read-only (`let`) to prevent manual writes.
    let modified: Date?
}

extension Issue {
    /// Applies an ``IssueFilter`` predicate as a WHERE clause.
    ///
    /// - `.open`: all issues (no additional predicate)
    /// - `.completed`: only completed issues
    /// - `.recent`: issues with activity in the last 7 days
    /// - `.tag`: issues associated with a specific tag (via subquery on ``IssueTag``)
    ///
    /// Chain `.where` after this to add further conditions (e.g. hiding completed issues).
    static func filter(with filter: IssueFilter) -> Where<Issue> {
        Self.where {
            switch filter {
            case .open: true
            case .completed: $0.isCompleted
            case .recent: $0.isRecent
            case let .tag(tag):
                $0.id.in(
                    IssueTag.select(\.issueID).where { $0.tagID.eq(tag.id) }
                )
            }
        }
    }
}

/// Ordering extension for pre-join issue queries (`Joins == ()`).
/// Must be called before any `.leftJoin` in the query chain.
extension Select where From == Issue, Joins == () {
    /// Appends an ORDER BY clause for the given ``IssueSortOrder`` field and direction.
    ///
    /// - `.priority`: sorts by priority column (nulls last in both directions)
    /// - `.date`: sorts by ``Issue/TableColumns/lastActivity`` (`modified ?? created`)
    /// - `.title`: sorts by title
    func order(by sortOrder: IssueSortOrder) -> Self {
        self.order {
            switch sortOrder.field {
            case .priority:
                if sortOrder.isAscending { $0.priority.asc(nulls: .last) } else { $0.priority.desc(nulls: .last) }
            case .date:
                if sortOrder.isAscending { $0.lastActivity.asc() } else { $0.lastActivity.desc() }
            case .title:
                if sortOrder.isAscending { $0.title.asc() } else { $0.title.desc() }
            }
        }
    }
}

/// Reusable SQL expressions for issue queries.
///
/// These are available as `$0.propertyName` inside StructuredQueries closures
/// (`.where`, `.order`, `.select`, etc.) wherever `Issue.TableColumns` is in scope.
/// Custom computed properties like these cannot be accessed via the static shorthand
/// (`Issue.lastActivity`) — only real `@Table` columns support that.
extension Issue.TableColumns {
    /// `IFNULL(modified, created)` — the most recent date the issue was touched.
    /// Used for date-based sorting and for computing ``isRecent``.
    var lastActivity: some QueryExpression<Date> {
        self.modified.ifnull(self.created)
    }

    /// `isCompleted != 1` — filters or counts non-completed issues.
    /// Uses `.neq(true)` so it works identically in both pre-join and post-join contexts.
    var isNotCompleted: some QueryExpression<Bool> {
        self.isCompleted.neq(true)
    }

    /// `lastActivity >= datetime('now', '-7 days', 'subsec')` — true for issues active in the last 7 days.
    var isRecent: some QueryExpression<Bool> {
        self.lastActivity.gte(#sql("datetime('now', '-7 days', 'subsec')"))
    }
}

extension Issue {
    var priorityColor: Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .green
        case nil: .gray
        }
    }
}
