import SwiftUI

struct ProductDetailView: View {
    let product: Product
    var cartVM: CartViewModel

    @State private var quantity: Int = 1
    @State private var showAddedAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // BUG #3: URL(string:) without percent-encoding — names with
                // spaces/special chars produce nil URLs, AsyncImage shows failure
                AsyncImage(url: URL(string: product.imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: product.sfSymbol)
                            .font(.system(size: 64))
                            .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(.fill.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(product.name)
                            .font(.title3.bold())

                        HStack {
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                Text("\(product.rating, specifier: "%.1f")")
                                    .font(.subheadline.weight(.medium))
                                Text("(\(product.reviewCount))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(product.category.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.fill.tertiary)
                            .clipShape(Capsule())
                    }

                    Divider()

                    // About
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }

                    Divider()

                    // Quantity
                    HStack {
                        Text("Quantity")
                            .font(.headline)

                        Spacer()

                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(quantity)")
                                .font(.title3.weight(.semibold))
                                .frame(minWidth: 28)

                            Button {
                                quantity += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                            }
                        }
                    }

                    // CTA
                    Button {
                        for _ in 0..<quantity {
                            cartVM.addToCart(product)
                        }
                        showAddedAlert = true
                    } label: {
                        Text("Add to Cart — $\(product.price * Double(quantity), specifier: "%.2f")")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.15)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
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
