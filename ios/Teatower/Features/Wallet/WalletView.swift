import SwiftUI
import PassKit

struct WalletView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var member: AudienceMember?
    @State private var isLoading = true
    @State private var showAddedConfirmation = false

    private var tier: LoyaltyTier {
        LoyaltyTier(rawValue: member?.loyaltyTier ?? "bronze") ?? .bronze
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card preview
                cardPreview

                // Add to Wallet button
                AddToWalletButton()
                    .frame(height: 48)
                    .padding(.horizontal, 40)

                // Info
                infoSection
            }
            .padding()
        }
        .background(Color.teatowerBg)
        .navigationTitle("Apple Wallet")
        .task {
            member = try? await supabase.fetchProfile()
            isLoading = false
        }
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        VStack(spacing: 0) {
            // Card top
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.white)
                    Text("TEATOWER")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(tier.emoji)
                        .font(.system(size: 24))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member?.displayName ?? "Tea Lover")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Statut \(tier.displayName)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(member?.loyaltyPoints ?? 0)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("points")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: tierColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Barcode area
            VStack(spacing: 8) {
                // Simulated barcode
                HStack(spacing: 1) {
                    ForEach(0..<40, id: \.self) { i in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: CGFloat.random(in: 1...3), height: 50)
                    }
                }
                .padding(.horizontal, 32)

                Text(member?.email ?? "")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.teatowerMuted)
            }
            .padding(16)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }

    private var tierColors: [Color] {
        switch tier {
        case .bronze: return [Color(hex: "8B4513"), Color(hex: "CD7F32")]
        case .silver: return [Color(hex: "757575"), Color(hex: "C0C0C0")]
        case .gold: return [Color(hex: "B8860B"), Color(hex: "FFD700")]
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Votre carte fidélité", systemImage: "wallet.pass.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            VStack(alignment: .leading, spacing: 10) {
                infoRow("creditcard", "Présentez la carte en boutique pour gagner des points")
                infoRow("arrow.triangle.2.circlepath", "Se met à jour automatiquement après chaque achat")
                infoRow("bell.badge", "Notifications de changement de statut")
                infoRow("lock.shield", "Données sécurisées, rien n'est stocké sur la carte")
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.teatowerBrown)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Add to Wallet Button (PassKit)

struct AddToWalletButton: UIViewRepresentable {
    func makeUIView(context: Context) -> PKAddPassButton {
        let button = PKAddPassButton(addPassButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.addToWallet), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKAddPassButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        @objc func addToWallet() {
            // In production: call Supabase Edge Function to generate .pkpass
            // then present PKAddPassesViewController
            print("Add to Wallet tapped — requires Edge Function to generate pass")
        }
    }
}
