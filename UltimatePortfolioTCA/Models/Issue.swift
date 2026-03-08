import Dependencies
import Foundation
import SQLiteData
import SwiftUI

@Table struct Issue: Hashable, Identifiable {
    enum Priority: Int, QueryBindable, CaseIterable, Identifiable {
        var id: Self { self }

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
    var priority: Priority = .low
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

extension Where<Issue> {
    /// Applies search text and token-based filters as additional WHERE clauses.
    ///
    /// Each parameter adds an independent condition (combined with AND):
    /// - **Search text**: Sanitized and matched via FTS5 prefix search against ``IssueText``.
    /// - **Tag tokens**: Issues must be associated with *all* selected tags (AND logic
    ///   via a grouped subquery on ``IssueTag``).
    /// - **Priority token**: Issues must match the selected ``Issue/Priority`` (first token wins).
    /// - **Status token**: Issues must match the selected ``SearchToken/Status``
    ///   — `.open` or `.completed` (first token wins).
    ///
    /// Parameters that are empty or absent produce no additional clauses,
    /// so calling this with no search text and an empty token array is a no-op.
    func filter(with searchQuery: String, tokens: [SearchToken]) -> Where<Issue> {
        let sanitizedFTS = IssueText.sanitize(query: searchQuery)
        let tagTokenIDs = tokens.compactMap(\.tag?.id)
        let priorityToken = tokens.compactMap(\.priority).first
        let statusToken = tokens.compactMap(\.status).first

        return self
            .where { // FTS5 full-text search
                if let sanitizedFTS {
                    // Search IssueText for matches, then get Issues based on their rowIDs
                    $0.rowid.in(IssueText.where { $0.match(sanitizedFTS) }.select { $0.rowid })
                }
            }
            .where { // Priority token filter
                if let priorityToken { $0.priority.eq(priorityToken) }
            }
            .where { // Status token filter
                if let statusToken {
                    switch statusToken {
                    case .open: $0.isNotCompleted
                    case .completed: $0.isCompleted
                    }
                }
            }
            .where { // Tag token filter (AND: must have all selected tags)
                if !tagTokenIDs.isEmpty {
                    $0.id.in(
                        IssueTag
                            .where { $0.tagID.in(tagTokenIDs) } // Get IssueTags that have corresponding tagIDs
                            .group(by: \.issueID) // group by issueID
                            .having { // if the count equals the tagTokenIDs count => Issue has all tags
                                $0.tagID.count(distinct: true).eq(tagTokenIDs.count)
                            }
                            .select(\.issueID) // get the corresponding IssueID
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
    /// - `.priority`: sorts by priority column
    /// - `.date`: sorts by ``Issue/TableColumns/lastActivity`` (`modified ?? created`)
    /// - `.title`: sorts by title
    func order(by sortOrder: IssueSortOrder) -> Self {
        order {
            switch sortOrder.field {
            case .priority:
                if sortOrder.isAscending { $0.priority.asc() } else { $0.priority.desc() }
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
        modified.ifnull(created)
    }

    /// `isCompleted != 1` — filters or counts non-completed issues.
    /// Uses `.neq(true)` so it works identically in both pre-join and post-join contexts.
    var isNotCompleted: some QueryExpression<Bool> {
        isCompleted.neq(true)
    }

    /// `lastActivity >= now.addingTimeInterval(-7 * 86400)` — true for issues active in the last 7 days.
    var isRecent: some QueryExpression<Bool> {
        @Dependency(\.date.now) var now
        let cutoff = now.addingTimeInterval(-7 * 86400)
        return lastActivity.gte(cutoff)
    }
}

extension Issue.Draft: Equatable {}

extension Issue.Priority {
    var color: Color {
        switch self {
        case .high: .red
        case .medium: .orange
        case .low: .green
        }
    }
}

extension Issue {
    var priorityColor: Color { priority.color }
}
