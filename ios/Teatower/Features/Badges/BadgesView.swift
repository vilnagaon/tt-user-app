import SwiftUI

struct BadgesView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var allBadges: [BadgeWithStatus] = []
    @State private var isLoading = true
    @State private var selectedBadge: BadgeWithStatus?

    private var earnedCount: Int { allBadges.filter(\.earned).count }
    private var totalCount: Int { allBadges.count }

    private let categories: [(key: String, label: String, icon: String)] = [
        ("explorer", "Explorateur", "map.fill"),
        ("loyalty", "Fidélité", "heart.fill"),
        ("connoisseur", "Connaisseur", "leaf.fill"),
        ("seasonal", "Saisons", "sparkles"),
        ("secret", "Secrets", "lock.fill"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView().padding(48)
                } else {
                    VStack(spacing: 24) {
                        headerCard
                        ForEach(categories, id: \.key) { cat in
                            categorySection(cat.key, label: cat.label, icon: cat.icon)
                        }
                    }
                    .padding()
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mes Badges")
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(badge: badge)
            }
        }
        .task { await loadBadges() }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.teatowerBorder, lineWidth: 8)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: totalCount > 0 ? CGFloat(earnedCount) / CGFloat(totalCount) : 0)
                    .stroke(Color.teatowerGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(earnedCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.teatowerGreen)
                    Text("/\(totalCount)")
                        .font(.system(size: 14))
                        .foregroundStyle(.teatowerMuted)
                }
            }

            Text("Collection de badges")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            Text("Explorez, dégustez, collectionnez.")
                .font(.teatowerBody)
                .foregroundStyle(.teatowerMuted)

            // Tier summary
            HStack(spacing: 16) {
                tierPill("🥉", count: allBadges.filter { $0.earned && $0.definition.tier == "bronze" }.count)
                tierPill("🥈", count: allBadges.filter { $0.earned && $0.definition.tier == "silver" }.count)
                tierPill("🥇", count: allBadges.filter { $0.earned && $0.definition.tier == "gold" }.count)
                tierPill("💎", count: allBadges.filter { $0.earned && $0.definition.tier == "platinum" }.count)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tierPill(_ emoji: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 14))
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(count > 0 ? .primary : .teatowerMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.teatowerBg)
        .clipShape(Capsule())
    }

    // MARK: - Category Section

    private func categorySection(_ category: String, label: String, icon: String) -> some View {
        let badges = allBadges.filter { $0.definition.category == category }
        let earnedInCat = badges.filter(\.earned).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.teatowerGreen)
                Spacer()
                Text("\(earnedInCat)/\(badges.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(earnedInCat == badges.count && badges.count > 0 ? .teatowerGreen : .teatowerMuted)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 90), spacing: 12)
            ], spacing: 12) {
                ForEach(badges) { badge in
                    BadgeTile(badge: badge)
                        .onTapGesture { selectedBadge = badge }
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Data

    private func loadBadges() async {
        do {
            let definitions: [BadgeDefinition] = try await supabase.client
                .from("badge_definitions")
                .select()
                .order("sort_order")
                .execute()
                .value

            let earned: [BadgeEarned] = try await supabase.client
                .from("badges_earned")
                .select()
                .execute()
                .value

            let earnedMap = Dictionary(uniqueKeysWithValues: earned.map { ($0.badgeId, $0.earnedAt) })

            allBadges = definitions.map { def in
                BadgeWithStatus(
                    definition: def,
                    earned: earnedMap[def.id] != nil,
                    earnedAt: earnedMap[def.id] ?? nil
                )
            }
        } catch {
            print("Failed to load badges: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Badge Tile (Gowalla style)

struct BadgeTile: View {
    let badge: BadgeWithStatus

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Tier ring
                Circle()
                    .stroke(badge.earned ? tierColor : Color.teatowerBorder.opacity(0.3), lineWidth: 3)
                    .frame(width: 64, height: 64)

                if badge.earned {
                    // Earned: full color emoji
                    Text(badge.definition.emoji)
                        .font(.system(size: 30))
                } else {
                    // Not earned: greyed out
                    Text(badge.definition.category == "secret" ? "❓" : badge.definition.emoji)
                        .font(.system(size: 30))
                        .grayscale(1)
                        .opacity(0.3)
                }

                // Tier indicator
                if badge.earned {
                    Circle()
                        .fill(tierColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Text(tierEmoji)
                                .font(.system(size: 8))
                        )
                        .offset(x: 24, y: -24)
                }
            }

            Text(badge.earned || badge.definition.category != "secret" ? badge.definition.name : "???")
                .font(.system(size: 10, weight: badge.earned ? .semibold : .regular))
                .foregroundStyle(badge.earned ? .primary : .teatowerMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
    }

    private var tierColor: Color {
        switch badge.definition.tier {
        case "bronze": return Color(hex: "CD7F32")
        case "silver": return Color(hex: "C0C0C0")
        case "gold": return Color(hex: "FFD700")
        case "platinum": return Color(hex: "E5E4E2")
        default: return .teatowerMuted
        }
    }

    private var tierEmoji: String {
        switch badge.definition.tier {
        case "bronze": return "🥉"
        case "silver": return "🥈"
        case "gold": return "🥇"
        case "platinum": return "💎"
        default: return ""
        }
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: BadgeWithStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.teatowerBorder)
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Big emoji
            Text(badge.definition.emoji)
                .font(.system(size: 72))

            Text(badge.definition.name)
                .font(.teatowerTitle)
                .foregroundStyle(.teatowerGreen)

            Text(badge.definition.description)
                .font(.teatowerBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Tier
            HStack(spacing: 8) {
                Text(badge.definition.tier.capitalized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(tierColor)
                    .clipShape(Capsule())

                Text(badge.definition.category.capitalized)
                    .font(.system(size: 14))
                    .foregroundStyle(.teatowerMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.teatowerBg)
                    .clipShape(Capsule())
            }

            Divider()

            if badge.earned {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Obtenu le \(badge.earnedAt?.formatted(date: .abbreviated, time: .omitted) ?? "—")")
                        .font(.teatowerBody)
                        .foregroundStyle(.primary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.teatowerMuted)
                    Text("Comment l'obtenir ?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(badge.definition.requirement)
                        .font(.teatowerBody)
                        .foregroundStyle(.teatowerMuted)
                }
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    private var tierColor: Color {
        switch badge.definition.tier {
        case "bronze": return Color(hex: "CD7F32")
        case "silver": return Color(hex: "C0C0C0")
        case "gold": return Color(hex: "FFD700")
        case "platinum": return Color(hex: "E5E4E2")
        default: return .teatowerMuted
        }
    }
}
