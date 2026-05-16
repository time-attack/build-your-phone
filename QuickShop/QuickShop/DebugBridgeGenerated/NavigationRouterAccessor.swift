import SwiftUI

#if DEBUG
import DebugBridge

@MainActor
enum NavigationRouterAccessor {
    static func register(on server: StateServer, instance: NavigationRouter) {
        server.registerRead("NavigationRouter_path") {
            "NavigationPath(count: \(instance.path.count))"
        }

        server.registerRead("NavigationRouter_selectedTab") {
            switch instance.selectedTab {
            case .home: return "home"
            case .cart: return "cart"
            case .profile: return "profile"
            }
        }

        server.registerWrite("NavigationRouter_path") { _ in
            instance.path = NavigationPath()
            DebugBridgeJSON.mutation("reset navigation")
            return true
        }

        server.registerWrite("NavigationRouter_selectedTab") { value in
            switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "home":
                instance.selectedTab = .home
            case "cart":
                instance.selectedTab = .cart
            case "profile":
                instance.selectedTab = .profile
            default:
                return false
            }
            DebugBridgeJSON.mutation("set selected tab")
            return true
        }
    }
}
#endif
