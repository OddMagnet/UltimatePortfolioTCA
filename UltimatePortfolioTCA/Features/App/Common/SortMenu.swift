import SwiftUI

/// A sort order that can be displayed in a ``SortMenu``.
///
/// Conforming enums provide a user-visible `label` and a `defaultAscending` direction
/// that is applied when the user first selects that order.
protocol SortOrderProtocol: CaseIterable, Equatable, Identifiable
where AllCases: RandomAccessCollection {
    var label: String { get }
    var defaultAscending: Bool { get }
}

/// A reusable toolbar menu that lists all cases of a ``SortOrderProtocol`` enum.
///
/// The currently active order shows a chevron indicating sort direction.
/// Selecting an order calls `onSelect`, keeping the view decoupled from TCA.
struct SortMenu<Order: SortOrderProtocol>: View {
    let currentOrder: Order
    let ascending: Bool
    let onSelect: (Order) -> Void

    var body: some View {
        Menu {
            ForEach(Order.allCases) { order in
                Button {
                    onSelect(order)
                } label: {
                    if order == currentOrder {
                        Label(order.label, systemImage: ascending ? "chevron.up" : "chevron.down")
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
