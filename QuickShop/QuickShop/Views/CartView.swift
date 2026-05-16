import SwiftUI

struct CartView: View {
    var cartVM: CartViewModel
    var router: NavigationRouter

    var body: some View {
        Group {
            if cartVM.isEmpty {
                ContentUnavailableView(
                    "Your cart is empty",
                    systemImage: "cart",
                    description: Text("Browse APIs, compute, and models to get started.")
                )
            } else {
                List {
                    ForEach(cartVM.items) { item in
                        HStack(spacing: 14) {
                            Image(systemName: item.product.sfSymbol)
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 1.0, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                Text("$\(item.product.price, specifier: "%.2f") / unit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Quantity stepper — uses updateQuantity which has BUG #1
                            HStack(spacing: 8) {
                                Button {
                                    cartVM.updateQuantity(for: item, quantity: item.quantity - 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(item.quantity)")
                                    .frame(minWidth: 20)
                                    .font(.subheadline.weight(.semibold))

                                Button {
                                    cartVM.updateQuantity(for: item, quantity: item.quantity + 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            cartVM.removeFromCart(cartVM.items[index])
                        }
                    }

                    Section {
                        HStack {
                            Text("Subtotal")
                                .font(.headline)
                            Spacer()
                            // BUG #1 surfaces here: total is stale after quantity changes
                            Text("$\(cartVM.total, specifier: "%.2f")")
                                .font(.title3.weight(.bold))
                        }

                        Button {
                            router.navigate(to: .checkout)
                        } label: {
                            Text("Continue to Checkout")
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
                        .listRowInsets(EdgeInsets())
                        .padding()
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Cart (\(cartVM.itemCount))")
    }
}
