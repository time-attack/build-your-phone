import Foundation
import SwiftUI

#if DEBUG
import DebugBridge

@MainActor
final class DebugBridgeManager {
    static let shared = DebugBridgeManager()

    private var server: MCPServer?

    private init() {}

    func start(
        cartVM: CartViewModel,
        productVM: ProductViewModel,
        profileVM: ProfileViewModel,
        router: NavigationRouter
    ) {
        if server != nil {
            return
        }

        let server = MCPServer()
        server.onConnect = {
            DebugBridgeNotifier.connected()
        }
        server.onDisconnect = {
            DebugBridgeNotifier.disconnected()
        }

        ScreenCapture.registerTools(on: server)
        TapInjector.registerTools(on: server)

        CartViewModelAccessor.registerTools(on: server, instance: cartVM)
        ProductViewModelAccessor.registerTools(on: server, instance: productVM)
        ProfileViewModelAccessor.registerTools(on: server, instance: profileVM)
        NavigationRouterAccessor.registerTools(on: server, instance: router)

        server.start()
        self.server = server

        DebugBridgeNotifier.action("bridge started")
        print("[iStack] Live-device DebugBridge started")
    }

    func stop() {
        server?.stop()
        server = nil
        DebugBridgeNotifier.disconnected()
        print("[iStack] Live-device DebugBridge stopped")
    }
}
#endif
