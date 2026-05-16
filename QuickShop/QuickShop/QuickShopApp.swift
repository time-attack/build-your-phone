import SwiftUI
#if DEBUG
import DebugBridge
#endif

@main
struct QuickShopApp: App {
    @State private var productVM = ProductViewModel()
    @State private var cartVM = CartViewModel()
    @State private var profileVM = ProfileViewModel()
    @State private var router = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedTab) {
                NavigationStack(path: $router.path) {
                    HomeView(productVM: productVM, cartVM: cartVM, router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(NavigationRouter.Tab.home)

                NavigationStack {
                    CartView(cartVM: cartVM, router: router)
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tabItem {
                    Label("Cart", systemImage: "cart.fill")
                }
                .tag(NavigationRouter.Tab.cart)
                .badge(cartVM.itemCount)

                NavigationStack {
                    ProfileView(profileVM: profileVM, router: router)
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(NavigationRouter.Tab.profile)
            }
            .tint(.green)
            .preferredColorScheme(.dark)
            #if DEBUG
            .debugBridgeOverlay()
            .task {
                DebugBridgeManager.shared.start(
                    cartVM: cartVM,
                    productVM: productVM,
                    profileVM: profileVM,
                    router: router
                )
            }
            #endif
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .productList(let category):
            ProductListView(productVM: productVM, cartVM: cartVM, router: router, category: category)
        case .productDetail(let product):
            ProductDetailView(product: product, cartVM: cartVM)
        case .cart:
            CartView(cartVM: cartVM, router: router)
        case .checkout:
            CheckoutView(cartVM: cartVM, router: router)
        case .profile:
            ProfileView(profileVM: profileVM, router: router)
        }
    }
}
