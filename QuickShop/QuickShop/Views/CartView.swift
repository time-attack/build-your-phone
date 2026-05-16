import SwiftUI

private let accent = Color.green

struct CartView: View {
    var cartVM: CartViewModel
    var router: NavigationRouter

    var body: some View {
        Group {
            if cartVM.isEmpty {
                ContentUnavailableView(
                    "Cart Empty",
                    systemImage: "cart",
                    description: Text("Add APIs, compute, or models to get started")
                )
            } else {
                List {
                    ForEach(cartVM.items) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.product.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(accent)
                                .frame(width: 44, height: 44)
                                .background(accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                Text("$\(item.product.price, specifier: "%.2f") / unit")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Quantity stepper — uses updateQuantity which has BUG #1
                            HStack(spacing: 8) {
                                Button {
                                    cartVM.updateQuantity(for: item, quantity: item.quantity - 1)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }

                                Text("\(item.quantity)")
                                    .frame(minWidth: 20)
                                    .font(.subheadline.weight(.medium).monospaced())

                                Button {
                                    cartVM.updateQuantity(for: item, quantity: item.quantity + 1)
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                            .foregroundStyle(accent)
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
                                .font(.headline.monospaced())
                        }

                        Button {
                            router.navigate(to: .checkout)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Deploy Order")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
