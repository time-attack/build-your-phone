import SwiftUI

struct ProductListView: View {
    @Bindable var productVM: ProductViewModel
    var cartVM: CartViewModel
    var router: NavigationRouter
    let category: Product.Category?

    var body: some View {
        let displayProducts: [Product] = {
            if let category = category {
                return productVM.products(in: category)
            }
            return productVM.filteredProducts
        }()

        List(displayProducts) { product in
            Button {
                router.navigate(to: .productDetail(product))
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: product.sfSymbol)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        // BUG #5: .fixedSize() prevents wrapping — long names push
                        // the price/button column off-screen
                        Text(product.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(product.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(product.rating, specifier: "%.1f") (\(product.reviewCount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.body.weight(.semibold))

                        Button {
                            cartVM.addToCart(product)
                        } label: {
                            Text("Add")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(Color(red: 1.0, green: 0.4, blue: 0.2))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle(category?.rawValue ?? "All Products")
        .searchable(text: $productVM.searchText, prompt: "Search APIs, models, tools...")
    }
}
