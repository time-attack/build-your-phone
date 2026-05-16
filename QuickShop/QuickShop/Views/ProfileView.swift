import SwiftUI

struct ProfileView: View {
    var profileVM: ProfileViewModel
    var router: NavigationRouter

    var body: some View {
        Group {
            if profileVM.isLoggedIn, let user = profileVM.currentUser {
                List {
                    // User header
                    Section {
                        HStack(spacing: 16) {
                            Text(String(user.name.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.4, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title3.bold())
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Member since \(user.memberSince, format: .dateTime.month(.abbreviated).year())")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Stats
                    Section("Account") {
                        HStack {
                            Label("Deployments", systemImage: "arrow.up.circle")
                            Spacer()
                            Text("\(user.orderCount)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("API Key", systemImage: "key")
                            Spacer()
                            Text("sk-\(user.id.uuidString.prefix(8).lowercased())")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Orders
                    Section("Recent Orders") {
                        if profileVM.orderHistory.isEmpty {
                            Text("No orders yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(profileVM.orderHistory) { order in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Order #\(order.id.uuidString.prefix(6).uppercased())")
                                            .font(.subheadline.weight(.medium))
                                        Text(order.date, format: .dateTime.month(.abbreviated).day().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("$\(order.total, specifier: "%.2f")")
                                            .font(.subheadline.weight(.medium))
                                        Text(order.status.rawValue)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(statusColor(order.status).opacity(0.12))
                                            .foregroundStyle(statusColor(order.status))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Logout
                    Section {
                        Button(role: .destructive) {
                            profileVM.logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                // Login
                VStack(spacing: 28) {
                    Spacer()

                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "bag.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Sign in to QuickShop")
                            .font(.title2.bold())
                        Text("Access your deployments, API keys, and billing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        Button {
                            profileVM.login(as: SampleData.sampleUser)
                        } label: {
                            Text("Continue as kai_dev")
                                .font(.body.weight(.semibold))
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

                        Button {
                            profileVM.login(as: SampleData.secondUser)
                        } label: {
                            Text("Continue as mx_runtime")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.fill.tertiary)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
        }
        .navigationTitle("Profile")
    }

    private func statusColor(_ status: Order.OrderStatus) -> Color {
        switch status {
        case .processing: .orange
        case .shipped: .blue
        case .delivered: .green
        }
    }
}
