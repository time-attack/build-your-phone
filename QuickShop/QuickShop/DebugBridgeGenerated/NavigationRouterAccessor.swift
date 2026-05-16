import SwiftUI

#if DEBUG
import DebugBridge

@MainActor
enum NavigationRouterAccessor {
    static func registerTools(on server: MCPServer, instance: NavigationRouter) {
        server.registerTool(MCPToolDefinition(
            name: "read_NavigationRouter_path",
            description: "Read NavigationRouter.path (NavigationPath)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                "NavigationPath(count: \(instance.path.count))"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "read_NavigationRouter_selectedTab",
            description: "Read NavigationRouter.selectedTab (home/cart/profile)",
            inputSchema: ["type": "object", "properties": [:] as [String: Any], "required": [] as [String]],
            handler: { _ in
                switch instance.selectedTab {
                case .home: return "home"
                case .cart: return "cart"
                case .profile: return "profile"
                }
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_NavigationRouter_path",
            description: "Reset NavigationRouter.path to root.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "string", "description": "Any value resets to root"] as [String: Any]],
                "required": []
            ] as [String: Any],
            handler: { _ in
                instance.path = NavigationPath()
                DebugBridgeJSON.mutation("reset navigation")
                return "OK: navigation path reset"
            }
        ))

        server.registerTool(MCPToolDefinition(
            name: "write_NavigationRouter_selectedTab",
            description: "Set NavigationRouter.selectedTab to home, cart, or profile.",
            inputSchema: [
                "type": "object",
                "properties": ["value": ["type": "string", "description": "home, cart, or profile"] as [String: Any]],
                "required": ["value"]
            ] as [String: Any],
            handler: { args in
                guard let value = args["value"] as? String else {
                    return "ERROR: expected string value"
                }

                switch value.lowercased() {
                case "home":
                    instance.selectedTab = .home
                case "cart":
                    instance.selectedTab = .cart
                case "profile":
                    instance.selectedTab = .profile
                default:
                    return "ERROR: expected home, cart, or profile"
                }

                DebugBridgeJSON.mutation("set selected tab")
                return "OK: selectedTab set to \(value.lowercased())"
            }
        ))
    }
}
#endif
