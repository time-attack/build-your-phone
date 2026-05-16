import Foundation
import Observation

@Observable
class ProductViewModel {
    var products: [Product] = SampleData.products
    var searchText: String = ""
    var selectedCategory: Product.Category? = nil

    var filteredProducts: [Product] {
        var result = products

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var featuredProducts: [Product] {
        Array(products.prefix(4))
    }

    var categories: [Product.Category] {
        Product.Category.allCases
    }

    func products(in category: Product.Category) -> [Product] {
        products.filter { $0.category == category }
    }
}
