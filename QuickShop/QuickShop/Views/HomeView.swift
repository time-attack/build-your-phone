import SwiftUI

struct HomeView: View {
    var productVM: ProductViewModel
    var cartVM: CartViewModel
    var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Hero
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 190)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("The developer\ninfrastructure store")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("APIs, compute, and models — ready to deploy.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(20)
                }
                .padding(.horizontal)

                // Categories
                VStack(alignment: .leading, spacing: 14) {
                    Text("Categories")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(productVM.categories, id: \.self) { category in
                                Button {
                                    router.navigate(to: .productList(category))
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: iconFor(category))
                                            .font(.subheadline)
                                        Text(category.rawValue)
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(.fill.tertiary)
                                    .clipShape(Capsule())
                                    .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Featured
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Featured")
                            .font(.title3.bold())
                        Spacer()
                        Button("View all") {
                            router.navigate(to: .productList(nil))
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
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

                // Trending
                VStack(alignment: .leading, spacing: 14) {
                    Text("Trending")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(Array(productVM.products.suffix(4).enumerated()), id: \.element.id) { index, product in
                            HStack(spacing: 14) {
                                Image(systemName: product.sfSymbol)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(
                                                LinearGradient(
                                                    colors: gradientFor(index),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    // BUG #5: .fixedSize() prevents text wrapping — long names
                                    // extend beyond the row and get clipped or overlap
                                    Text(product.name)
                                        .font(.subheadline.weight(.medium))
                                        .fixedSize(horizontal: true, vertical: false)
                                    Text("$\(product.price, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    cartVM.addToCart(product)
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color(red: 1.0, green: 0.4, blue: 0.2))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)

                            if index < 3 {
                                Divider().padding(.leading, 70)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("QuickShop")
    }

    private func iconFor(_ category: Product.Category) -> String {
        switch category {
        case .apis: "cloud.fill"
        case .compute: "cpu.fill"
        case .models: "brain"
        case .devtools: "wrench.and.screwdriver.fill"
        }
    }

    private func gradientFor(_ index: Int) -> [Color] {
        let palettes: [[Color]] = [
            [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 1.0)],
            [Color(red: 1.0, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.3)],
            [Color(red: 0.2, green: 0.7, blue: 0.6), Color(red: 0.3, green: 0.8, blue: 0.7)],
            [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.5, blue: 0.6)],
        ]
        return palettes[index % palettes.count]
    }
}

struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // BUG #3: URL(string:) without percent-encoding — URLs with spaces/special
            // chars return nil, so AsyncImage gets nil and shows the failure state
            AsyncImage(url: URL(string: product.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: product.sfSymbol)
                        .font(.title)
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 156, height: 110)
            .background(.fill.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // BUG #5: .fixedSize() prevents wrapping — long names push beyond card width
            Text(product.name)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: 156, alignment: .leading)
                .clipped()

            Text("$\(product.price, specifier: "%.2f")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
