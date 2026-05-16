import Foundation
import SwiftUI

#if DEBUG
import DebugBridge

@MainActor
final class DebugBridgeManager {
    static let shared = DebugBridgeManager()

    private var server: StateServer?

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

        let server = StateServer()

        CartViewModelAccessor.register(on: server, instance: cartVM)
        ProductViewModelAccessor.register(on: server, instance: productVM)
        ProfileViewModelAccessor.register(on: server, instance: profileVM)
        NavigationRouterAccessor.register(on: server, instance: router)

        server.start()
        self.server = server

        DebugBridgeNotifier.action("state server started")
        print("[iStack] StateServer started on port 9999")
    }

    func stop() {
        server?.stop()
        server = nil
        DebugBridgeNotifier.disconnected()
        print("[iStack] StateServer stopped")
    }
}
#endif
