import SwiftUI

struct RecommendationsView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var member: AudienceMember?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let member, !member.teaProfile.favoriteTypes.isNilOrEmpty {
                        // Personalized recommendations based on profile
                        recommendationCards(member)
                    } else {
                        // No profile yet — show discovery
                        discoverySection
                    }

                    // Always show: seasonal picks
                    seasonalSection
                }
                .padding()
            }
            .background(Color.teatowerBg)
            .navigationTitle("Découvrir")
        }
        .task {
            member = try? await supabase.fetchProfile()
        }
    }

    private func recommendationCards(_ m: AudienceMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Pour vous", systemImage: "sparkles")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Basé sur vos \(m.totalOrders) achats et vos préférences.")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)

            // This will use Claude API in a future sprint
            VStack(spacing: 12) {
                recommendCard(
                    emoji: "🍵",
                    title: "Matcha Japonais",
                    reason: "Votre catégorie préférée — avez-vous essayé le Matcha Cérémonie ?",
                    color: .teatowerGreen
                )
                recommendCard(
                    emoji: "🌸",
                    title: "Sakura",
                    reason: "Édition de printemps — parfait pour la saison.",
                    color: .pink
                )
                recommendCard(
                    emoji: "🧊",
                    title: "Collection Glacée",
                    reason: "L'été arrive — découvrez nos infusions à froid.",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func recommendCard(emoji: String, title: String, reason: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(.teatowerMuted)
        }
        .padding(12)
        .background(Color.teatowerBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var discoverySection: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.teatowerBrown)

            Text("Complétez votre Tea Profile")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Plus on vous connaît, meilleures seront nos recommandations.\nAllez dans Mon Profil pour ajouter vos préférences.")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var seasonalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sélection de saison", systemImage: "sun.max.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerBrown)

            HStack(spacing: 12) {
                seasonCard(emoji: "🌿", name: "Infusion du Printemps", price: "10,00€")
                seasonCard(emoji: "🍃", name: "Vert Jasmin", price: "10,00€")
                seasonCard(emoji: "🍵", name: "Matcha Japonais", price: "20,00€")
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func seasonCard(emoji: String, name: String, price: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 28))
            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(price)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.teatowerBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.teatowerBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}
