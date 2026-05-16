import SwiftUI

private let accent = Color.green

struct HomeView: View {
    var productVM: ProductViewModel
    var cartVM: CartViewModel
    var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero banner — terminal style
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                        )
                        .frame(height: 180)

                    VStack(spacing: 8) {
                        Text("> QuickShop")
                            .font(.title.bold().monospaced())
                            .foregroundStyle(accent)
                        Text("APIs. Compute. Models. Ship it.")
                            .font(.subheadline.monospaced())
                            .foregroundStyle(accent.opacity(0.7))
                        Text("GStack x GBrain Hackathon")
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)

                // Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(productVM.categories, id: \.self) { category in
                                Button {
                                    router.navigate(to: .productList(category))
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: iconFor(category))
                                            .font(.title2)
                                            .frame(width: 50, height: 50)
                                            .background(accent.opacity(0.15))
                                            .foregroundStyle(accent)
                                            .clipShape(Circle())
                                        Text(category.rawValue)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Featured products
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Featured")
                            .font(.title2.bold())
                        Spacer()
                        Button("See All") {
                            router.navigate(to: .productList(nil))
                        }
                        .font(.subheadline)
                        .foregroundStyle(accent)
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(productVM.featuredProducts) { product in
                                Button {
                                    router.navigate(to: .productDetail(product))
                                } label: {
                                    ProductCardView(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Quick add section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    ForEach(Array(productVM.products.suffix(4))) { product in
                        HStack(spacing: 12) {
                            Image(systemName: product.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(accent)
                                .frame(width: 44, height: 44)
                                .background(accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                // BUG #5: .fixedSize() prevents text wrapping — long names
                                // extend beyond the row and get clipped or overlap
                                Text(product.name)
                                    .font(.subheadline.weight(.medium))
                                    .fixedSize(horizontal: true, vertical: false)
                                Text("$\(product.price, specifier: "%.2f")")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                cartVM.addToCart(product)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("QuickShop")
    }

    private func iconFor(_ category: Product.Category) -> String {
        switch category {
        case .apis: "icloud.fill"
        case .compute: "cpu.fill"
        case .models: "brain"
        case .devtools: "hammer.fill"
        }
    }
}

struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // BUG #3: URL(string:) without percent-encoding — URLs with spaces/special
            // chars return nil, so AsyncImage gets nil and shows the failure state
            AsyncImage(url: URL(string: product.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(accent)
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: product.sfSymbol)
                        .font(.largeTitle)
                        .foregroundStyle(accent)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 150, height: 120)
            .background(accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // BUG #5: .fixedSize() prevents wrapping — long names push beyond card width
            Text(product.name)
                .font(.caption.weight(.medium))
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 150, alignment: .leading)
                .clipped()

            Text("$\(product.price, specifier: "%.2f")")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}
