import SwiftUI

struct LoginView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var email = ""
    @State private var isSending = false
    @State private var linkSent = false
    @State private var errorMessage: String?

    // TEST bypass — remove before production
    #if DEBUG
    @State private var showTestBypass = false
    private let testPassword = "teatower2026"
    @State private var testPasswordInput = ""
    #endif

    var body: some View {
        ZStack {
            Color.teatowerBg.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo on green background (like emails/website)
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.teatowerGreen)
                            .frame(height: 100)
                        AsyncImage(url: URL(string: "https://teatower.com/cdn/shop/files/Teatower_-_logo_-BELGIAN_TEA_HOUSE.png")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180)
                            default:
                                // Fallback: text logo on green
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 24))
                                    Text("TEATOWER")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 40)

                    Text("Mon Espace Thé")
                        .font(.teatowerTitle)
                        .foregroundStyle(.teatowerGreen)
                        .padding(.top, 16)

                    Text("Votre profil, vos achats,\nvos recommandations.")
                        .font(.teatowerBody)
                        .foregroundStyle(.teatowerMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
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

                        // TEST BYPASS — DEBUG only
                        #if DEBUG
                        Divider().padding(.vertical, 4)

                        Button("Test: bypass login") {
                            showTestBypass = true
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.5))
                        #endif
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
        #if DEBUG
        .alert("Test Login", isPresented: $showTestBypass) {
            TextField("Email", text: $email)
            SecureField("Password", text: $testPasswordInput)
            Button("Cancel", role: .cancel) {}
            Button("Login") {
                if testPasswordInput == testPassword && email.contains("@") {
                    Task { await testBypassLogin() }
                }
            }
        } message: {
            Text("Debug bypass — enter email and test password")
        }
        #endif
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

    #if DEBUG
    private func testBypassLogin() async {
        // Sign in with Supabase email+password (for testing only)
        do {
            try await supabase.client.auth.signIn(email: email, password: testPasswordInput)
            await supabase.checkSession()
        } catch {
            errorMessage = "Test login failed: \(error.localizedDescription)"
        }
    }
    #endif
}
