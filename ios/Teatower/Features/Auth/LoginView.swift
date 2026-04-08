import SwiftUI

struct LoginView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var email = ""
    @State private var isSending = false
    @State private var linkSent = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.teatowerBg.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    TeatowerLogo(width: 180)

                    Text("Mon Espace Thé")
                        .font(.teatowerTitle)
                        .foregroundStyle(.teatowerGreen)

                    Text("Votre profil, vos achats,\nvos recommandations.")
                        .font(.teatowerBody)
                        .foregroundStyle(.teatowerMuted)
                        .multilineTextAlignment(.center)
                }

                if linkSent {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.teatowerGreen)

                        Text("Vérifiez votre boîte mail")
                            .font(.teatowerHeading)
                            .foregroundStyle(.teatowerGreen)

                        Text("Un lien de connexion a été envoyé à\n**\(email)**")
                            .font(.teatowerBody)
                            .foregroundStyle(.teatowerMuted)
                            .multilineTextAlignment(.center)

                        Button("Renvoyer le lien") {
                            Task { await sendMagicLink() }
                        }
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerBrown)
                    }
                    .padding(32)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                } else {
                    VStack(spacing: 16) {
                        TextField("votre@email.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .background(Color.teatowerBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button(action: { Task { await sendMagicLink() } }) {
                            HStack {
                                if isSending {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Recevoir mon lien de connexion")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(email.contains("@") ? Color.teatowerGreen : Color.gray.opacity(0.4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!email.contains("@") || isSending)

                        if let error = errorMessage {
                            Text(error)
                                .font(.teatowerCaption)
                                .foregroundStyle(.red)
                        }

                        Text("Pas de mot de passe.\nUn lien sécurisé vous sera envoyé par email.")
                            .font(.caption)
                            .foregroundStyle(.teatowerMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                }

                Spacer()

                Text("En vous connectant, vous acceptez notre politique\nde confidentialité (RGPD).")
                    .font(.system(size: 10))
                    .foregroundStyle(.teatowerMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private func sendMagicLink() async {
        isSending = true
        errorMessage = nil
        do {
            try await supabase.sendMagicLink(email: email)
            linkSent = true
        } catch {
            errorMessage = "Impossible d'envoyer le lien. Vérifiez votre email."
        }
        isSending = false
    }
}
