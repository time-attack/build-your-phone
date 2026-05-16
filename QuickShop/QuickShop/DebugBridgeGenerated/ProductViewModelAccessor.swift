import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum ProductViewModelAccessor {
    static func registerTools(on server: MCPServer, instance: ProductViewModel) {
        server.registerTool(MCPToolDefinition(
            name: "read_ProductViewModel_products",
            description: "Read ProductViewModel.products ([Product])",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
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
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_ProductViewModel_searchText",
            description: "Read ProductViewModel.searchText (String)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in instance.searchText }
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_ProductViewModel_selectedCategory",
            description: "Read ProductViewModel.selectedCategory (Product.Category?)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                instance.selectedCategory?.rawValue ?? "null"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProductViewModel_products",
            description: "Set ProductViewModel.products. Passing [] creates an empty catalog edge case.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "array", "description": "Use [] to clear products"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                guard let value = args["value"] as? [Any], value.isEmpty else {
                    instance.products = []
                    DebugBridgeJSON.mutation("clear products")
                    return "OK: products cleared; complex product construction is not generated"
                }

                instance.products = []
                DebugBridgeJSON.mutation("clear products")
                return "OK: products set to \(value)"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProductViewModel_searchText",
            description: "Set ProductViewModel.searchText (String)",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "string", "description": "Search text"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                guard let value = args["value"] as? String else {
                    return "ERROR: expected string value"
                }

                instance.searchText = value
                DebugBridgeJSON.mutation("set product search")
                return "OK: searchText set to \(value)"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProductViewModel_selectedCategory",
            description: "Set ProductViewModel.selectedCategory. Use null or empty string to clear.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": ["string", "null"], "description": "electronics, clothing, home, sports, or null"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                if args["value"] is NSNull {
                    instance.selectedCategory = nil
                    DebugBridgeJSON.mutation("clear selected category")
                    return "OK: selectedCategory set to nil"
                }

                guard let value = args["value"] as? String else {
                    instance.selectedCategory = nil
                    DebugBridgeJSON.mutation("clear selected category")
                    return "OK: selectedCategory set to nil"
                }

                let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if normalized.isEmpty || normalized == "null" {
                    instance.selectedCategory = nil
                    DebugBridgeJSON.mutation("clear selected category")
                    return "OK: selectedCategory set to nil"
                }

                if let category = Product.Category.allCases.first(where: {
                    $0.rawValue.lowercased() == normalized || String(describing: $0).lowercased() == normalized
                }) {
                    instance.selectedCategory = category
                    DebugBridgeJSON.mutation("set selected category")
                    return "OK: selectedCategory set to \(category.rawValue)"
                }

                return "ERROR: unknown category \(value)"
            }
        ))
    }
}
#endif
