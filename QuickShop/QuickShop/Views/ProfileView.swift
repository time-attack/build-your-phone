import SwiftUI

private let accent = Color.green

struct ProfileView: View {
    var profileVM: ProfileViewModel
    var router: NavigationRouter

    var body: some View {
        Group {
            if profileVM.isLoggedIn, let user = profileVM.currentUser {
                List {
                    // User info header
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: user.avatarSymbol)
                                .font(.system(size: 44))
                                .foregroundStyle(accent)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title3.bold().monospaced())
                                Text(user.email)
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(.secondary)
                                Text("Since \(user.memberSince, format: .dateTime.month(.abbreviated).year())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Stats
                    Section("Usage") {
                        HStack {
                            Label("Deployments", systemImage: "arrow.up.circle.fill")
                                .foregroundStyle(accent)
                            Spacer()
                            Text("\(user.orderCount)")
                                .font(.body.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Label("API Key", systemImage: "key.fill")
                                .foregroundStyle(accent)
                            Spacer()
                            Text("sk-\(user.id.uuidString.prefix(8).lowercased())")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Order history
                    Section("Recent Deployments") {
                        if profileVM.orderHistory.isEmpty {
                            Text("No deployments yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(profileVM.orderHistory) { order in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("deploy-\(order.id.uuidString.prefix(8).lowercased())")
                                            .font(.subheadline.weight(.medium).monospaced())
                                        Text(order.date, format: .dateTime.month().day().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("$\(order.total, specifier: "%.2f")")
                                            .font(.subheadline.weight(.medium).monospaced())
                                        Text(order.status.rawValue)
                                            .font(.caption.monospaced())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(statusColor(order.status).opacity(0.15))
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
                                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                // Login screen
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "terminal")
                        .font(.system(size: 60))
                        .foregroundStyle(accent.opacity(0.6))

                    Text("> authenticate")
                        .font(.title2.bold().monospaced())
                        .foregroundStyle(accent)

                    Text("Sign in to access your dev resources")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        Button {
                            profileVM.login(as: SampleData.sampleUser)
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                Text("kai_dev")
                                    .fontDesign(.monospaced)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            profileVM.login(as: SampleData.secondUser)
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                Text("mx_runtime")
                                    .fontDesign(.monospaced)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accent.opacity(0.15))
                            .foregroundStyle(accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
        }
        .navigationTitle("Profile")
    }

    private func statusColor(_ status: Order.OrderStatus) -> Color {
        switch status {
        case .processing: .orange
        case .shipped: .cyan
        case .delivered: .green
        }
    }
}
