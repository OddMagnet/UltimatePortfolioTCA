import Foundation
import StructuredQueries

@Table struct Tag: Identifiable {
    typealias ID = UUID

    let id: ID
    var name = ""
}
