import SwiftUI

struct SettingsView: View {
    @Environment(SupabaseManager.self) private var supabase

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

                Section("Notifications") {
                    Toggle("Nouvelles collections", isOn: .constant(true))
                    Toggle("Promotions", isOn: .constant(true))
                    Toggle("Ateliers & événements", isOn: .constant(true))
                }

                Section("Données") {
                    NavigationLink("Politique de confidentialité") {
                        Text("RGPD — Vos données sont stockées en Europe (Supabase, Ireland) et ne sont jamais partagées avec des tiers.")
                            .padding()
                    }
                    Button("Exporter mes données") {}
                        .foregroundStyle(.teatowerGreen)
                    Button("Supprimer mon compte", role: .destructive) {}
                }

                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Sprint 2)")
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
        }
    }
}
