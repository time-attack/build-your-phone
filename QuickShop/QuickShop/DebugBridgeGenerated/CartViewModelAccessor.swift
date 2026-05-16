import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum CartViewModelAccessor {
    static func register(on server: StateServer, instance: CartViewModel) {
        server.registerRead("CartViewModel_items") {
            DebugBridgeJSON.stringify(instance.items.map { item in
                [
                    "id": item.id.uuidString,
                    "product": [
                        "id": item.product.id.uuidString,
                        "name": item.product.name,
                        "price": item.product.price,
                        "category": item.product.category.rawValue
                    ],
                    "quantity": item.quantity
                ] as [String: Any]
            })
        }

        server.registerRead("CartViewModel_total") {
            "\(instance.total)"
        }

        server.registerWrite("CartViewModel_items") { value in
            instance.items = []
            instance.total = 0
            DebugBridgeJSON.mutation("clear cart items")
            return true
        }

        server.registerWrite("CartViewModel_total") { value in
            if let num = Double(value) {
                instance.total = num
                DebugBridgeJSON.mutation("set cart total")
                return true
            }
            return false
        }
    }
}
#endif
