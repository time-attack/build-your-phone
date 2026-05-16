import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum ProfileViewModelAccessor {
    static func registerTools(on server: MCPServer, instance: ProfileViewModel) {
        server.registerTool(MCPToolDefinition(
            name: "read_ProfileViewModel_currentUser",
            description: "Read ProfileViewModel.currentUser (User?)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                guard let user = instance.currentUser else {
                    return "null"
                }

                return DebugBridgeJSON.stringify([
                    "id": user.id.uuidString,
                    "name": user.name,
                    "email": user.email,
                    "avatarSymbol": user.avatarSymbol,
                    "memberSince": ISO8601DateFormatter().string(from: user.memberSince),
                    "orderCount": user.orderCount
                ] as [String: Any])
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_ProfileViewModel_isLoggedIn",
            description: "Read ProfileViewModel.isLoggedIn (Bool)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in "\(instance.isLoggedIn)" }
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_ProfileViewModel_orderHistory",
            description: "Read ProfileViewModel.orderHistory ([Order])",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                DebugBridgeJSON.stringify(instance.orderHistory.map { order in
                    [
                        "id": order.id.uuidString,
                        "total": order.total,
                        "date": ISO8601DateFormatter().string(from: order.date),
                        "status": order.status.rawValue,
                        "itemCount": order.items.count
                    ] as [String: Any]
                })
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProfileViewModel_currentUser",
            description: "Set ProfileViewModel.currentUser. Use null to clear.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": ["object", "string", "null"], "description": "Use null to clear"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                if args["value"] is NSNull {
                    instance.currentUser = nil
                    DebugBridgeJSON.mutation("clear current user")
                    return "OK: currentUser set to nil"
                }

                if let value = args["value"] as? String, value.isEmpty || value.lowercased() == "null" {
                    instance.currentUser = nil
                    DebugBridgeJSON.mutation("clear current user")
                    return "OK: currentUser set to nil"
                }

                instance.currentUser = nil
                DebugBridgeJSON.mutation("clear current user")
                return "OK: currentUser cleared; complex user construction is not generated"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProfileViewModel_isLoggedIn",
            description: "Set ProfileViewModel.isLoggedIn (Bool)",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "boolean", "description": "Login state"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                if let value = args["value"] as? Bool {
                    instance.isLoggedIn = value
                    DebugBridgeJSON.mutation("set login state")
                    return "OK: isLoggedIn set to \(value)"
                }
                if let value = args["value"] as? String {
                    instance.isLoggedIn = value.lowercased() == "true" || value == "1"
                    DebugBridgeJSON.mutation("set login state")
                    return "OK: isLoggedIn set to \(instance.isLoggedIn)"
                }
                return "ERROR: expected boolean value"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_ProfileViewModel_orderHistory",
            description: "Set ProfileViewModel.orderHistory. Passing [] clears orders.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "array", "description": "Use [] to clear order history"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                guard let value = args["value"] as? [Any], value.isEmpty else {
                    instance.orderHistory = []
                    DebugBridgeJSON.mutation("clear order history")
                    return "OK: orderHistory cleared; complex order construction is not generated"
                }

                instance.orderHistory = []
                DebugBridgeJSON.mutation("clear order history")
                return "OK: orderHistory set to \(value)"
            }
        ))
    }
}
#endif
