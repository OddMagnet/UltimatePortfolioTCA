import Foundation
import SQLiteData

@Table struct IssueText: FTS5, Identifiable {
    @Column(primaryKey: true) let rowid: Int
    var id: Int { rowid }
    let title: String
    let detail: String
}

extension IssueText {
    /// Sanitizes user input for safe use with FTS5 `.match()`.
    ///
    /// Strips FTS5 operators (`"`, `*`, `+`, `-`, `()`, etc.), double-quotes
    /// each term for literal matching, and appends `*` for prefix matching.
    /// Multiple terms are joined with spaces, which FTS5 treats as implicit AND.
    /// Returns `nil` if input is empty or contains only whitespace/special characters.
    ///
    /// ```
    /// sanitize(query: "fix login")    // → "\"fix\"* \"login\"*"  (matches both)
    /// sanitize(query: "fix")          // → "\"fix\"*"            (matches fix, fixed, fixing…)
    /// sanitize(query: "fix \"login")  // → "\"fix\"* \"login\"*" (strips stray quote)
    /// sanitize(query: "")             // → nil                   (no FTS filter applied)
    /// sanitize(query: "***")          // → nil                   (only special chars)
    /// ```
    static func sanitize(query: String) -> String? {
        let specialCharacters = CharacterSet(charactersIn: "\"*+-()^{}:,")
        let terms = query
            .unicodeScalars
            .filter { !specialCharacters.contains($0) } // Remove FTS5 special characters from input
            .split(separator: " ") // Split input into individual terms
            .map(String.init) // Convert them back to strings
            .filter { !$0.isEmpty }
        guard !terms.isEmpty else { return nil }
        // Wrap terms in double quotes for literal matching and apply * for prefix matching
        return terms.map { "\"\($0)\"*" }.joined(separator: " ")
    }
}
