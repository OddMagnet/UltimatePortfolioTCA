import Foundation
import StructuredQueries

@Table struct Tag: Hashable, Identifiable {
    typealias ID = UUID

    let id: ID
    var name = ""
}
