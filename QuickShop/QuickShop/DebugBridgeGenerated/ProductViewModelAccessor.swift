import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum ProductViewModelAccessor {
    static func register(on server: StateServer, instance: ProductViewModel) {
        server.registerRead("ProductViewModel_products") {
            DebugBridgeJSON.stringify(instance.products.map { product in
                [
                    "id": product.id.uuidString,
                    "name": product.name,
                    "description": product.description,
                    "price": product.price,
                    "category": product.category.rawValue,
                    "sfSymbol": product.sfSymbol,
                    "rating": product.rating,
                    "reviewCount": product.reviewCount
                ] as [String: Any]
            })
        }

        server.registerRead("ProductViewModel_searchText") {
            instance.searchText
        }

        server.registerRead("ProductViewModel_selectedCategory") {
            instance.selectedCategory?.rawValue ?? "null"
        }

        server.registerWrite("ProductViewModel_products") { value in
            instance.products = []
            DebugBridgeJSON.mutation("clear products")
            return true
        }

        server.registerWrite("ProductViewModel_searchText") { value in
            instance.searchText = value
            DebugBridgeJSON.mutation("set product search")
            return true
        }

        server.registerWrite("ProductViewModel_selectedCategory") { value in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalized.isEmpty || normalized == "null" {
                instance.selectedCategory = nil
                DebugBridgeJSON.mutation("clear selected category")
                return true
            }

            if let category = Product.Category.allCases.first(where: {
                $0.rawValue.lowercased() == normalized || String(describing: $0).lowercased() == normalized
            }) {
                instance.selectedCategory = category
                DebugBridgeJSON.mutation("set selected category")
                return true
            }

            return false
        }
    }
}
#endif
