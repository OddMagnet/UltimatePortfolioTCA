import SwiftUI

/// A sort order combining a sort field with a direction, displayed in a ``SortMenu``.
///
/// Conforming structs pair a `Field` enum (the sortable columns) with an `ascending` flag.
/// The `init(field:)` initializer sets each field's natural default direction.
///
/// Default implementations provided via extension:
/// - `apply(_:)`: Same field toggles direction; different field replaces with the selected value
/// - `allFields`: All fields with their default direction (via `init(_:)`)
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
    mutating func apply(_ selected: Self)
}

extension SortOrderProtocol {
    var id: Field { field }

    /// Applies a sort order selection.
    ///
    /// - Same field: toggles the current direction (asc ↔ desc).
    /// - Different field: replaces `self` with `selected`, carrying its direction as-is.
    mutating func apply(_ selected: Self) {
        if id == selected.id {
            isAscending.toggle()
        } else {
            self = selected
        }
    }

    /// All fields with their default ascending direction.
    static var allFields: [Self] {
        Field.allCases.map { Self($0) }
    }
}

/// A reusable toolbar menu that lists all fields of a ``SortOrderProtocol`` type.
///
/// The currently active sort field shows a chevron indicating direction.
/// Selecting any field calls `onSelect` with an order built from ``allFields`` (via `init(_:)`),
/// so it carries each field's default direction. Use ``SortOrderProtocol/apply(_:)`` in the
/// reducer to toggle same-field selections and switch with the default direction otherwise.
struct SortMenu<Order: SortOrderProtocol, ExtraActions: View>: View {
    let currentOrder: Order
    let onSelect: (Order) -> Void
    let extraActions: ExtraActions?

    init(currentOrder: Order, onSelect: @escaping (Order) -> Void, @ViewBuilder extraActions: () -> ExtraActions) {
        self.currentOrder = currentOrder
        self.onSelect = onSelect
        self.extraActions = extraActions()
    }

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

            extraActions
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}

extension SortMenu where ExtraActions == Never {
    init(currentOrder: Order, onSelect: @escaping (Order) -> Void) {
        self.currentOrder = currentOrder
        self.onSelect = onSelect
        extraActions = nil
    }
}
