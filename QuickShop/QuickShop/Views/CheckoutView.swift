import SwiftUI

struct CheckoutView: View {
    var cartVM: CartViewModel
    var router: NavigationRouter

    @State private var apiKeyName = ""
    @State private var webhookURL = ""
    @State private var billingEmail = ""
    @State private var showConfirmation = false

    var body: some View {
        Form {
            // BUG #2: Force-unwrap crashes when cart is empty
            // If user navigates here with an empty cart (e.g., via deep link or back-nav
            // after clearing cart), this will crash
            Section("Order Summary") {
                let primaryItem = cartVM.items.first!
                HStack {
                    Image(systemName: primaryItem.product.sfSymbol)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
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

                    VStack(alignment: .leading) {
                        Text(primaryItem.product.name)
                            .font(.subheadline.weight(.medium))
                        if cartVM.items.count > 1 {
                            Text("+ \(cartVM.items.count - 1) more items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text("$\(cartVM.total, specifier: "%.2f")")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.2))
                }
            }

            Section("Provisioning") {
                TextField("API key name", text: $apiKeyName)
                    .textContentType(.name)
                TextField("Webhook URL (optional)", text: $webhookURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
            }

            Section("Billing") {
                TextField("Email", text: $billingEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            }

            Section {
                Button {
                    showConfirmation = true
                } label: {
                    Text("Place Order")
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
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Order placed!", isPresented: $showConfirmation) {
            Button("OK") {
                cartVM.clearCart()
                router.popToRoot()
            }
        } message: {
            Text("Your resources are provisioning. You'll receive API keys at your billing email.")
        }
    }
}
