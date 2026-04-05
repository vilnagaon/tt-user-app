import SwiftUI

struct TeaProfileView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var member: AudienceMember?
    @State private var tags: [String] = []
    @State private var isLoading = true
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView().padding(48)
                } else if let member {
                    VStack(spacing: 20) {
                        headerCard(member)
                        statsGrid(member)
                        tagsSection
                        teaPreferencesCard(member)
                        tasteProfileCard(member)
                    }
                    .padding()
                } else {
                    ContentUnavailableView(
                        "Profil en cours de création",
                        systemImage: "person.crop.circle.badge.clock",
                        description: Text("Votre Tea Profile sera disponible après votre premier achat.")
                    )
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mon Profil")
            .refreshable { await loadProfile() }
        }
        .task { await loadProfile() }
    }

    // MARK: - Header

    private func headerCard(_ m: AudienceMember) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(storeColor(m.preferredStore))
                    .frame(width: 72, height: 72)
                Text(m.firstName?.prefix(1).uppercased() ?? "T")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(m.displayName.isEmpty ? "Tea Lover" : m.displayName)
                .font(.teatowerTitle)
                .foregroundStyle(.teatowerGreen)

            Text(m.email)
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)

            HStack(spacing: 8) {
                if m.sourceOdoo { sourceBadge("Boutique", icon: "storefront.fill", color: .storeNamur) }
                if m.sourceShopify { sourceBadge("E-shop", icon: "globe", color: .storeOnline) }
                if m.sourceMailchimp { sourceBadge("Newsletter", icon: "envelope.fill", color: .teatowerBrown) }
            }

            if let store = m.preferredStore {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                    Text("Boutique préférée : \(store.displayName)")
                }
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerBrown)
            }

            if m.isMultiChannel {
                Text("Client multi-canal")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.teatowerGreen.opacity(0.15))
                    .foregroundStyle(.teatowerGreen)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sourceBadge(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(label).font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    // MARK: - Stats

    private func statsGrid(_ m: AudienceMember) -> some View {
        HStack(spacing: 12) {
            statCard(value: "\(m.totalOrders)", label: "Achats", sub: "\(m.totalOrdersPos) boutique · \(m.totalOrdersOnline) en ligne")
            statCard(value: String(format: "%.0f€", NSDecimalNumber(decimal: m.avgBasket).doubleValue), label: "Panier moy.", sub: nil)
            statCard(value: String(format: "%.0f€", NSDecimalNumber(decimal: m.lifetimeValue).doubleValue), label: "Valeur totale", sub: memberSince(m))
        }
    }

    private func statCard(value: String, label: String, sub: String?) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.teatowerGreen)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)
            if let sub {
                Text(sub)
                    .font(.system(size: 9))
                    .foregroundStyle(.teatowerMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func memberSince(_ m: AudienceMember) -> String {
        guard let date = m.firstPurchaseDate else { return "" }
        return "depuis \(date.formatted(.dateTime.month(.wide).year()))"
    }

    // MARK: - Tags

    private var tagsSection: some View {
        Group {
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Mes badges", systemImage: "tag.fill")
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerMuted)
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tagDisplayName(tag))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(tagColor(tag).opacity(0.12))
                                .foregroundStyle(tagColor(tag))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func tagDisplayName(_ tag: String) -> String {
        switch tag {
        case "vip": return "VIP"
        case "multi_canal": return "Multi-canal"
        case "nouveau": return "Nouveau client"
        case "dormant": return "Nous manquez"
        case "client_namur": return "Namur"
        case "client_liege": return "Liège"
        case "client_waterloo": return "Waterloo"
        case "client_online": return "E-shop"
        default: return tag.capitalized
        }
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "vip": return .orange
        case "multi_canal": return .purple
        case "nouveau": return .teatowerGreen
        case "dormant": return .red
        case "client_namur": return .storeNamur
        case "client_liege": return .storeLiege
        case "client_waterloo": return .storeWaterloo
        case "client_online": return .storeOnline
        default: return .teatowerMuted
        }
    }

    // MARK: - Tea Preferences

    private func teaPreferencesCard(_ m: AudienceMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Mes Préférences", systemImage: "leaf.fill")
                    .font(.teatowerHeading)
                    .foregroundStyle(.teatowerGreen)
                Spacer()
                Button(isEditing ? "Terminé" : "Modifier") {
                    isEditing.toggle()
                }
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerBrown)
            }

            let types = m.teaProfile.favoriteTypes ?? []
            if !types.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Types préférés")
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerMuted)
                    FlowLayout(spacing: 8) {
                        ForEach(types, id: \.self) { type in
                            Text(type)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.teatowerGreen.opacity(0.1))
                                .foregroundStyle(.teatowerGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                Text("Ajoutez vos préférences pour recevoir des recommandations sur mesure.")
                    .font(.teatowerBody)
                    .foregroundStyle(.teatowerMuted)
            }

            if let method = m.teaProfile.brewingMethod {
                infoRow("Méthode d'infusion", value: method)
            }
            if let freq = m.teaProfile.frequency {
                infoRow("Fréquence", value: freq)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Taste Profile

    private func tasteProfileCard(_ m: AudienceMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Mon Palais", systemImage: "mouth.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            if let taste = m.teaProfile.taste {
                tasteBar("Sucré", value: taste.sweet ?? 0, emoji: "🍯")
                tasteBar("Amer", value: taste.bitter ?? 0, emoji: "🍵")
                tasteBar("Floral", value: taste.floral ?? 0, emoji: "🌸")
                tasteBar("Épicé", value: taste.spicy ?? 0, emoji: "🌶️")
                tasteBar("Fruité", value: taste.fruity ?? 0, emoji: "🍑")
                tasteBar("Terreux", value: taste.earthy ?? 0, emoji: "🌿")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 32))
                        .foregroundStyle(.teatowerMuted)
                    Text("Complétez votre profil gustatif\npour des recommandations sur mesure")
                        .font(.teatowerBody)
                        .foregroundStyle(.teatowerMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tasteBar(_ label: String, value: Int, emoji: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji).font(.system(size: 14))
            Text(label)
                .font(.teatowerCaption)
                .frame(width: 50, alignment: .trailing)
                .foregroundStyle(.teatowerMuted)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teatowerBg)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teatowerGreen)
                        .frame(width: geo.size.width * CGFloat(value) / 5, height: 10)
                }
            }
            .frame(height: 10)
            Text("\(value)/5")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.teatowerGreen)
                .frame(width: 28)
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.teatowerCaption).foregroundStyle(.teatowerMuted)
            Spacer()
            Text(value).font(.teatowerBody).foregroundStyle(.teatowerGreen)
        }
    }

    private func storeColor(_ store: StoreId?) -> Color {
        switch store {
        case .waterloo: return .storeWaterloo
        case .namur: return .storeNamur
        case .liege: return .storeLiege
        case .online: return .storeOnline
        case nil: return .teatowerGreen
        }
    }

    // MARK: - Data

    private func loadProfile() async {
        do {
            member = try await supabase.fetchProfile()
            tags = try await supabase.fetchTags()
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }
}
