import SwiftUI

/// A sort order combining a sort field with a direction, displayed in a ``SortMenu``.
///
/// Conforming structs pair a `Field` enum (the sortable columns) with an `ascending` flag.
/// The `init(field:)` initializer sets each field's natural default direction.
///
/// Required conformances:
/// - `Codable`: Persists the user's choice to `UserDefaults` via `@Shared(.appStorage(...))`
/// - `Equatable`: Enables full-value comparison (field + isAscending)
/// - `Identifiable`: `id` is the `field`, identifying the sort order regardless of direction.
///   Used for stable `ForEach` identity in ``SortMenu`` and for same-field comparison in reducers
protocol SortOrderProtocol: Codable, Equatable, Identifiable where ID == Field {
    associatedtype Field: CaseIterable
    var field: Field { get }
    var isAscending: Bool { get set }
    var label: String { get }
    init(_ field: Field)
}

extension SortOrderProtocol {
    var id: Field { field }

    mutating func toggle() {
        isAscending.toggle()
    }

    /// All fields with their default ascending direction.
    static var allFields: [Self] {
        Field.allCases.map { Self($0) }
    }
}

/// A reusable toolbar menu that lists all fields of a ``SortOrderProtocol`` type.
///
/// The currently active sort field shows a chevron indicating direction.
/// Selecting any field calls `onSelect`; the consumer decides whether to toggle or switch.
struct SortMenu<Order: SortOrderProtocol>: View {
    let currentOrder: Order
    let onSelect: (Order) -> Void

    var body: some View {
        Menu {
            ForEach(Order.allFields) { order in
                Button {
                    onSelect(order)
                } label: {
                    if order.id == currentOrder.id {
                        Label(order.label, systemImage: currentOrder.isAscending ? "chevron.up" : "chevron.down")
                    } else {
                        Text(order.label)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}
