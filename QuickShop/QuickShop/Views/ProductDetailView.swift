import SwiftUI

private let accent = Color.green

struct ProductDetailView: View {
    let product: Product
    var cartVM: CartViewModel

    @State private var quantity: Int = 1
    @State private var showAddedAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // BUG #3: URL(string:) without percent-encoding — names with
                // spaces/special chars produce nil URLs, AsyncImage shows failure
                AsyncImage(url: URL(string: product.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(accent)
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: product.sfSymbol)
                            .font(.system(size: 80))
                            .foregroundStyle(accent)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    // Product info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title2.bold())

                        HStack {
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.title3.weight(.semibold).monospaced())
                                .foregroundStyle(accent)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(product.rating, specifier: "%.1f")")
                                    .font(.subheadline.weight(.medium))
                                Text("(\(product.reviewCount) reviews)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(product.category.rawValue)
                            .font(.subheadline.monospaced())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.15))
                            .foregroundStyle(accent)
                            .clipShape(Capsule())
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Quantity selector
                    HStack {
                        Text("Quantity")
                            .font(.headline)

                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }

                            Text("\(quantity)")
                                .font(.title3.weight(.medium).monospaced())
                                .frame(minWidth: 30)

                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }
                        }
                    }

                    // Add to cart button
                    Button {
                        for _ in 0..<quantity {
                            cartVM.addToCart(product)
                        }
                        showAddedAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add to Cart — $\(product.price * Double(quantity), specifier: "%.2f")")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Added to Cart", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(quantity) x \(product.name) added to your cart.")
        }
    }
}
