import Foundation
import Observation

@Observable
class CartViewModel {
    var items: [CartItem] = []
    var total: Double = 0.0

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    func addToCart(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(id: UUID(), product: product, quantity: 1))
        }
        recalculateTotal()
    }

    func removeFromCart(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        recalculateTotal()
    }

    // BUG #1: This method updates the quantity but does NOT recalculate the total.
    // The total only updates when items are added or removed, not when quantity changes.
    func updateQuantity(for item: CartItem, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
            recalculateTotal()
        } else {
            items[index].quantity = quantity
            // Missing: recalculateTotal() — total becomes stale after quantity change
        }
    }

    func clearCart() {
        items.removeAll()
        recalculateTotal()
    }

    private func recalculateTotal() {
        total = items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
}
