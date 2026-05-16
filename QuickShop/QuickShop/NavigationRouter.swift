import SwiftUI
import Observation

@Observable
class NavigationRouter {
    var path = NavigationPath()
    var selectedTab: Tab = .home

    enum Tab: Hashable {
        case home
        case cart
        case profile
    }

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
