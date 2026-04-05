import SwiftUI

struct RecommendationsView: View {
    let email: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Placeholder — will use Claude API in Sprint 3
                    ContentUnavailableView(
                        "Recommandations personnalisées",
                        systemImage: "sparkles",
                        description: Text("Bientôt disponible. Vos recommandations seront basées sur vos achats et votre profil gustatif.")
                    )
                }
                .padding()
            }
            .background(Color.teatowerBg)
            .navigationTitle("Découvrir")
        }
    }
}
