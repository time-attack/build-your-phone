import SwiftUI

private let accent = Color.green

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
                HStack(spacing: 12) {
                    Image(systemName: product.sfSymbol)
                        .font(.title2)
                        .foregroundStyle(accent)
                        .frame(width: 50, height: 50)
                        .background(accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        // BUG #5: .fixedSize() prevents wrapping — long names push
                        // the price/button column off-screen
                        Text(product.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(product.category.rawValue)
                            .font(.caption.monospaced())
                            .foregroundStyle(accent.opacity(0.7))

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("\(product.rating, specifier: "%.1f") (\(product.reviewCount))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.body.weight(.semibold).monospaced())

                        Button {
                            cartVM.addToCart(product)
                        } label: {
                            Text("Add")
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(accent)
                                .foregroundStyle(.black)
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
