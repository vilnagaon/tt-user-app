import SwiftUI

struct TeaProfileView: View {
    let email: String
    @State private var member: AudienceMember?
    @State private var isLoading = true
    @Environment(\.supabaseClient) private var supabase

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(48)
                } else if let member {
                    VStack(spacing: 20) {
                        headerCard(member)
                        statsGrid(member)
                        teaPreferencesCard(member)
                        tasteProfileCard(member)
                    }
                    .padding()
                } else {
                    Text("Profil introuvable")
                        .foregroundStyle(.teatowerMuted)
                        .padding(48)
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mon Profil")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await loadProfile() }
    }

    // MARK: - Header Card

    private func headerCard(_ m: AudienceMember) -> some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.teatowerGreen)
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

            // Source badges
            HStack(spacing: 8) {
                if m.sourceOdoo {
                    sourceBadge("Boutique", icon: "storefront.fill", color: .storeNamur)
                }
                if m.sourceShopify {
                    sourceBadge("E-shop", icon: "globe", color: .storeOnline)
                }
                if m.sourceMailchimp {
                    sourceBadge("Newsletter", icon: "envelope.fill", color: .teatowerBrown)
                }
            }

            if let store = m.preferredStore {
                Text("Boutique préférée : \(store.displayName)")
                    .font(.teatowerCaption)
                    .foregroundStyle(.teatowerBrown)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sourceBadge(_ label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    // MARK: - Stats Grid

    private func statsGrid(_ m: AudienceMember) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 12) {
            statCard("Achats", value: "\(m.totalOrders)", sub: "\(m.totalOrdersPos) boutique · \(m.totalOrdersOnline) en ligne")
            statCard("Panier moyen", value: "\(m.avgBasket)€", sub: nil)
            statCard("Valeur totale", value: "\(m.lifetimeValue)€", sub: "depuis \(m.firstPurchaseDate?.formatted(.dateTime.year()) ?? "—")")
        }
    }

    private func statCard(_ title: String, value: String, sub: String?) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.teatowerKPI)
                .foregroundStyle(.teatowerGreen)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(title)
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)
            if let sub {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(.teatowerMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Tea Preferences

    private func teaPreferencesCard(_ m: AudienceMember) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Mes Préférences", systemImage: "leaf.fill")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            let types = m.teaProfile.favoriteTypes ?? []
            if !types.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Types de thé préférés")
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
                tasteBar("Sucré", value: taste.sweet ?? 0)
                tasteBar("Amer", value: taste.bitter ?? 0)
                tasteBar("Floral", value: taste.floral ?? 0)
                tasteBar("Épicé", value: taste.spicy ?? 0)
                tasteBar("Fruité", value: taste.fruity ?? 0)
                tasteBar("Terreux", value: taste.earthy ?? 0)
            } else {
                Text("Complétez votre profil gustatif pour des recommandations sur mesure.")
                    .font(.teatowerBody)
                    .foregroundStyle(.teatowerMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tasteBar(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.teatowerCaption)
                .frame(width: 60, alignment: .trailing)
                .foregroundStyle(.teatowerMuted)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teatowerBg)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teatowerGreen)
                        .frame(width: geo.size.width * CGFloat(value) / 5, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(value)/5")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.teatowerGreen)
                .frame(width: 30)
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.teatowerCaption)
                .foregroundStyle(.teatowerMuted)
            Spacer()
            Text(value)
                .font(.teatowerBody)
                .foregroundStyle(.teatowerGreen)
        }
    }

    // MARK: - Data

    private func loadProfile() async {
        guard let supabase else { return }
        do {
            let response: AudienceMember = try await supabase
                .from("audience")
                .select()
                .eq("email", value: email)
                .single()
                .execute()
                .value
            member = response
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}
