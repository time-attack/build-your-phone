import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let category: Category
    let imageURL: String
    let sfSymbol: String
    let rating: Double
    let reviewCount: Int

    enum Category: String, CaseIterable, Hashable {
        case apis = "APIs"
        case compute = "Compute"
        case models = "Models"
        case devtools = "DevTools"
    }
}

struct CartItem: Identifiable, Hashable {
    let id: UUID
    let product: Product
    var quantity: Int
}

struct User: Identifiable {
    let id: UUID
    var name: String
    var email: String
    var avatarSymbol: String
    var memberSince: Date
    var orderCount: Int
}

struct Order: Identifiable {
    let id: UUID
    let items: [CartItem]
    let total: Double
    let date: Date
    let status: OrderStatus

    enum OrderStatus: String {
        case processing = "Provisioning"
        case shipped = "Deploying"
        case delivered = "Active"
    }
}

enum AppRoute: Hashable {
    case productList(Product.Category?)
    case productDetail(Product)
    case cart
    case checkout
    case profile
}
