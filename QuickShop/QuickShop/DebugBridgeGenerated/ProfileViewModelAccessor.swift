import Foundation

#if DEBUG
import DebugBridge

@MainActor
enum ProfileViewModelAccessor {
    static func register(on server: StateServer, instance: ProfileViewModel) {
        server.registerRead("ProfileViewModel_currentUser") {
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

        server.registerRead("ProfileViewModel_isLoggedIn") {
            "\(instance.isLoggedIn)"
        }

        server.registerRead("ProfileViewModel_orderHistory") {
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

        server.registerWrite("ProfileViewModel_currentUser") { value in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalized.isEmpty || normalized == "null" {
                instance.currentUser = nil
                DebugBridgeJSON.mutation("clear current user")
                return true
            }
            // Complex user construction not supported; only clearing
            instance.currentUser = nil
            DebugBridgeJSON.mutation("clear current user")
            return true
        }

        server.registerWrite("ProfileViewModel_isLoggedIn") { value in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            instance.isLoggedIn = normalized == "true" || normalized == "1"
            DebugBridgeJSON.mutation("set login state")
            return true
        }

        server.registerWrite("ProfileViewModel_orderHistory") { value in
            instance.orderHistory = []
            DebugBridgeJSON.mutation("clear order history")
            return true
        }
    }
}
#endif
