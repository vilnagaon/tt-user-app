import SwiftUI

struct RecommendationsView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var service = RecommendationService.shared
    @State private var member: AudienceMember?
    @State private var purchases: [Purchase] = []
    @State private var tags: [String] = []
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if service.isLoading {
                        loadingCard
                    } else if !service.recommendations.isEmpty {
                        // Personal message from Trevor
                        if let msg = service.personalMessage {
                            trevorMessage(msg)
                        }

                        // Pour vous
                        let pourVous = service.recommendations.filter { $0.category == "pour vous" }
                        if !pourVous.isEmpty {
                            sectionCard(title: "Pour vous", icon: "heart.fill", color: .teatowerGreen, recs: pourVous)
                        }

                        // À découvrir
                        let decouvrir = service.recommendations.filter { $0.category == "à découvrir" }
                        if !decouvrir.isEmpty {
                            sectionCard(title: "À découvrir", icon: "sparkles", color: .teatowerBrown, recs: decouvrir)
                        }

                        // Saison
                        let saison = service.recommendations.filter { $0.category == "saison" }
                        if !saison.isEmpty {
                            sectionCard(title: "Sélection de saison", icon: "sun.max.fill", color: .orange, recs: saison)
                        }
                    } else if (member?.teaProfile.favoriteTypes ?? []).isEmpty {
                        noProfileCard
                    } else {
                        noProfileCard
                    }
                }
                .padding()
            }
            .background(Color.teatowerBg)
            .navigationTitle("Découvrir")
            .refreshable { await loadAndRecommend() }
        }
        .task {
            guard !hasLoaded else { return }
            await loadAndRecommend()
            hasLoaded = true
        }
    }

    // MARK: - Trevor Message

    private func trevorMessage(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.teatowerGreen)
                    .frame(width: 40, height: 40)
                Text("🍵")
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Trevor, votre sommelier")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Section Card

    private func sectionCard(title: String, icon: String, color: Color, recs: [RecommendationService.TeaRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.teatowerHeading)
                .foregroundStyle(color)

            ForEach(recs) { rec in
                recommendationRow(rec, accentColor: color)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func recommendationRow(_ rec: RecommendationService.TeaRecommendation, accentColor: Color) -> some View {
        HStack(spacing: 14) {
            // Emoji avatar
            Text(rec.emoji)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(rec.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    // Match score
                    Text("\(rec.matchScore)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(matchColor(rec.matchScore))
                        .clipShape(Capsule())
                }
                Text(rec.reason)
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
                    .lineLimit(2)
                if !rec.sku.isEmpty {
                    Text(rec.sku)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.teatowerMuted.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(Color.teatowerBg.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func matchColor(_ score: Int) -> Color {
        if score >= 85 { return .teatowerGreen }
        if score >= 70 { return .teatowerBrown }
        return .teatowerMuted
    }

    // MARK: - Loading

    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.teatowerGreen)
            Text("Trevor prépare vos recommandations...")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noProfileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.teatowerBrown)

            Text("Complétez votre Tea Profile")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Plus on vous connaît, meilleures seront vos recommandations.\nAllez dans Mon Profil pour renseigner vos goûts.")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data

    private func loadAndRecommend() async {
        do {
            member = try await supabase.fetchProfile()
            purchases = try await supabase.fetchPurchases()
            tags = try await supabase.fetchTags()

            if let member {
                await service.generateRecommendations(
                    member: member,
                    purchases: purchases,
                    tags: tags
                )
            }
        } catch {
            print("Failed to load recommendations: \(error)")
        }
    }
}
