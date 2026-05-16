import SwiftUI

private let accent = Color.green

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
                        .font(.title3)
                        .foregroundStyle(accent)
                        .frame(width: 40, height: 40)
                        .background(accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

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
                        .font(.headline.weight(.bold).monospaced())
                        .foregroundStyle(accent)
                }
            }

            Section("Provisioning") {
                TextField("API Key Name", text: $apiKeyName)
                    .textContentType(.name)
                    .font(.body.monospaced())
                TextField("Webhook URL (optional)", text: $webhookURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .font(.body.monospaced())
            }

            Section("Billing") {
                TextField("Email", text: $billingEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .font(.body.monospaced())
            }

            Section {
                Button {
                    showConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "terminal")
                            Text("Deploy")
                        }
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
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Deployed!", isPresented: $showConfirmation) {
            Button("OK") {
                cartVM.clearCart()
                router.popToRoot()
            }
        } message: {
            Text("Your resources are provisioning. API keys will appear in your dashboard.")
        }
    }
}
