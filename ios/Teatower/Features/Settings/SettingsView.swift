import SwiftUI

struct SettingsView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var pushService = PushNotificationService.shared
    @State private var pushPromo = true
    @State private var pushRestock = true
    @State private var pushNewArrival = true
    @State private var pushBadge = true
    @State private var pushLoyalty = true

    var body: some View {
        NavigationStack {
            List {
                Section("Compte") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(supabase.currentEmail ?? "—")
                            .foregroundStyle(.teatowerMuted)
                    }
                }

                Section("Notifications push") {
                    if !pushService.isAuthorized {
                        Button {
                            Task { await pushService.requestPermission() }
                        } label: {
                            Label("Activer les notifications", systemImage: "bell.badge.fill")
                                .foregroundStyle(.teatowerGreen)
                        }
                    } else {
                        Toggle("Promotions & offres", isOn: $pushPromo)
                        Toggle("Réapprovisionnement", isOn: $pushRestock)
                        Toggle("Nouvelles collections", isOn: $pushNewArrival)
                        Toggle("Badges gagnés", isOn: $pushBadge)
                        Toggle("Changement de statut fidélité", isOn: $pushLoyalty)
                    }
                }
                .onChange(of: pushPromo) { _, _ in Task { await savePushPrefs() } }
                .onChange(of: pushRestock) { _, _ in Task { await savePushPrefs() } }
                .onChange(of: pushNewArrival) { _, _ in Task { await savePushPrefs() } }
                .onChange(of: pushBadge) { _, _ in Task { await savePushPrefs() } }
                .onChange(of: pushLoyalty) { _, _ in Task { await savePushPrefs() } }

                Section("Données") {
                    NavigationLink("Politique de confidentialité") {
                        ScrollView {
                            Text("Conformément au RGPD, vos données sont stockées en Europe (Supabase, Ireland). Elles ne sont jamais partagées avec des tiers. Vous disposez d'un droit d'accès, de modification et de suppression de vos données.")
                                .padding()
                        }
                        .navigationTitle("Confidentialité")
                    }
                    Button("Exporter mes données") {}
                        .foregroundStyle(.teatowerGreen)
                    Button("Supprimer mon compte", role: .destructive) {}
                }

                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(.teatowerMuted)
                    }
                    Link("teatower.com", destination: URL(string: "https://teatower.com")!)
                }

                Section {
                    Button("Se déconnecter", role: .destructive) {
                        Task { await supabase.signOut() }
                    }
                }
            }
            .navigationTitle("Réglages")
            .task { await loadPushPrefs() }
        }
    }

    private func loadPushPrefs() async {
        await pushService.checkStatus()
        guard let member = try? await supabase.fetchProfile() else { return }
        // Load from custom_fields or audience columns
        // For now, defaults are true
    }

    private func savePushPrefs() async {
        guard let email = supabase.currentEmail else { return }
        try? await supabase.client
            .from("audience")
            .update([
                "push_promo": pushPromo,
                "push_restock": pushRestock,
                "push_new_arrival": pushNewArrival,
                "push_badge": pushBadge,
                "push_loyalty": pushLoyalty,
            ])
            .eq("email", value: email)
            .execute()
    }
}
