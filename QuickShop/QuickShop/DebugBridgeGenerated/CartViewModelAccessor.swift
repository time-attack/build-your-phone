import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum CartViewModelAccessor {
    static func registerTools(on server: MCPServer, instance: CartViewModel) {
        server.registerTool(MCPToolDefinition(
            name: "read_CartViewModel_items",
            description: "Read CartViewModel.items ([CartItem])",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
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
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_CartViewModel_total",
            description: "Read CartViewModel.total (Double)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in "\(instance.total)" }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_CartViewModel_items",
            description: "Set CartViewModel.items. Passing [] clears the cart.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "array", "description": "Use [] to clear cart items"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                guard let value = args["value"] as? [Any], value.isEmpty else {
                    instance.items = []
                    instance.total = 0
                    DebugBridgeJSON.mutation("clear cart items")
                    return "OK: items cleared; complex item construction is not generated"
                }

                instance.items = []
                instance.total = 0
                DebugBridgeJSON.mutation("clear cart items")
                return "OK: items set to \(value)"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_CartViewModel_total",
            description: "Set CartViewModel.total (Double)",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "number", "description": "New total"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                if let value = args["value"] as? Double {
                    instance.total = value
                    DebugBridgeJSON.mutation("set cart total")
                    return "OK: total set to \(value)"
                }
                if let value = args["value"] as? Int {
                    instance.total = Double(value)
                    DebugBridgeJSON.mutation("set cart total")
                    return "OK: total set to \(Double(value))"
                }
                return "ERROR: expected numeric value"
            }
        ))
    }
}
#endif
