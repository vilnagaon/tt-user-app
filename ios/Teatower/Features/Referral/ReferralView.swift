import SwiftUI

struct ReferralView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var referralCode: String?
    @State private var referralCount = 0
    @State private var isLoading = true
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.teatowerGreen)

                    Text("Partagez le plaisir du thé")
                        .font(.teatowerTitle)
                        .foregroundStyle(.teatowerGreen)

                    Text("Invitez un ami → il reçoit **-10%**\nVous recevez **-10%** + **50 points** fidélité")
                        .font(.teatowerBody)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Code card
                if let code = referralCode {
                    VStack(spacing: 16) {
                        Text("Votre code parrainage")
                            .font(.teatowerCaption)
                            .foregroundStyle(.teatowerMuted)

                        Text(code)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(.teatowerGreen)
                            .padding(20)
                            .background(Color.teatowerBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = code
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            } label: {
                                Label(copied ? "Copié !" : "Copier", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(copied ? Color.green : Color.teatowerGreen)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }

                            ShareLink(item: "Découvrez Teatower avec mon code \(code) et profitez de -10% sur votre première commande ! 🍵 teatower.com") {
                                Label("Partager", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .foregroundStyle(.teatowerGreen)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.teatowerGreen, lineWidth: 1.5))
                            }
                        }
                    }
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Stats
                VStack(spacing: 12) {
                    HStack {
                        VStack(spacing: 4) {
                            Text("\(referralCount)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.teatowerGreen)
                            Text("amis parrainés")
                                .font(.teatowerCaption)
                                .foregroundStyle(.teatowerMuted)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 40)

                        VStack(spacing: 4) {
                            Text("\(referralCount * 50)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.teatowerBrown)
                            Text("points gagnés")
                                .font(.teatowerCaption)
                                .foregroundStyle(.teatowerMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // How it works
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comment ça marche ?")
                        .font(.teatowerHeading)
                        .foregroundStyle(.teatowerGreen)

                    stepRow("1", "Partagez votre code", "Envoyez-le à vos amis par message, email ou réseaux sociaux.")
                    stepRow("2", "Votre ami commande", "Il utilise votre code sur teatower.com et reçoit -10%.")
                    stepRow("3", "Vous êtes récompensé(e)", "Vous recevez -10% sur votre prochaine commande + 50 points fidélité.")
                }
                .padding(20)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .background(Color.teatowerBg)
        .navigationTitle("Parrainage")
            .teatowerBranded()
        .task { await loadReferral() }
    }

    private func stepRow(_ number: String, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.teatowerGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(desc).font(.system(size: 12)).foregroundStyle(.teatowerMuted)
            }
        }
    }

    private func loadReferral() async {
        guard let email = supabase.currentEmail else { return }
        do {
            // Get or generate referral code
            let member = try await supabase.fetchProfile()
            if let existing = member?.referralCode {
                referralCode = existing
            } else {
                // Generate code
                try await supabase.client.rpc("generate_referral_code", params: ["target_email": email]).execute()
                let updated = try await supabase.fetchProfile()
                referralCode = updated?.referralCode
            }
            referralCount = member?.referralCount ?? 0
        } catch {
            print("Referral load failed: \(error)")
        }
        isLoading = false
    }
}
