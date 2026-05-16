import Foundation
import Observation

@Observable
class ProfileViewModel {
    var currentUser: User? = nil
    var isLoggedIn: Bool = false
    var orderHistory: [Order] = []

    // BUG #4: cachedUserData is set on first login and NEVER cleared on logout.
    // Logging in as a different user will still show the first user's cached data
    // until the app is restarted.
    private var cachedUserData: User? = nil

    func login(as user: User) {
        if let cached = cachedUserData {
            // Returns stale cached data instead of the new user
            currentUser = cached
        } else {
            cachedUserData = user
            currentUser = user
        }
        isLoggedIn = true
        loadOrderHistory()
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        orderHistory = []
        // BUG: cachedUserData is NOT cleared here
        // cachedUserData = nil  // This line is missing
    }

    func loadOrderHistory() {
        guard let user = currentUser else { return }
        // Simulate some order history
        orderHistory = [
            Order(
                id: UUID(),
                items: [CartItem(id: UUID(), product: SampleData.products[0], quantity: 1)],
                total: SampleData.products[0].price,
                date: Date().addingTimeInterval(-86400 * 7),
                status: .delivered
            ),
            Order(
                id: UUID(),
                items: [
                    CartItem(id: UUID(), product: SampleData.products[3], quantity: 2),
                    CartItem(id: UUID(), product: SampleData.products[5], quantity: 1),
                ],
                total: SampleData.products[3].price * 2 + SampleData.products[5].price,
                date: Date().addingTimeInterval(-86400 * 2),
                status: .shipped
            ),
            Order(
                id: UUID(),
                items: [CartItem(id: UUID(), product: SampleData.products[7], quantity: 3)],
                total: SampleData.products[7].price * 3,
                date: Date(),
                status: .processing
            ),
        ]
    }
}
