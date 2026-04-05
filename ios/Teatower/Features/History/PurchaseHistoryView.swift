import SwiftUI

struct PurchaseHistoryView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var purchases: [Purchase] = []
    @State private var isLoading = true

    private var groupedByMonth: [(String, [Purchase])] {
        let grouped = Dictionary(grouping: purchases) { purchase in
            purchase.orderDate.formatted(.dateTime.month(.wide).year())
        }
        return grouped.sorted { a, b in
            purchases.first(where: { $0.orderDate.formatted(.dateTime.month(.wide).year()) == a.key })?.orderDate ?? .distantPast >
            purchases.first(where: { $0.orderDate.formatted(.dateTime.month(.wide).year()) == b.key })?.orderDate ?? .distantPast
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().padding(48)
                } else if purchases.isEmpty {
                    ContentUnavailableView(
                        "Pas encore d'achats",
                        systemImage: "bag",
                        description: Text("Vos achats en boutique et en ligne apparaîtront ici automatiquement.")
                    )
                } else {
                    ScrollView {
                        // Summary card
                        summaryCard
                            .padding(.horizontal)
                            .padding(.top)

                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(groupedByMonth, id: \.0) { month, monthPurchases in
                                Section {
                                    ForEach(monthPurchases) { purchase in
                                        PurchaseRow(purchase: purchase)
                                            .padding(.horizontal)
                                    }
                                } header: {
                                    Text(month)
                                        .font(.teatowerCaption)
                                        .foregroundStyle(.teatowerMuted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(Color.teatowerBg)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mes Achats")
            .refreshable { await loadPurchases() }
        }
        .task { await loadPurchases() }
    }

    private var summaryCard: some View {
        let total = purchases.reduce(Decimal.zero) { $0 + $1.total }
        let posCount = purchases.filter { $0.source != "shopify" }.count
        let onlineCount = purchases.filter { $0.source == "shopify" }.count

        return HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(purchases.count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
                Text("achats")
                    .font(.system(size: 11))
                    .foregroundStyle(.teatowerMuted)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 2) {
                Text(String(format: "%.0f€", NSDecimalNumber(decimal: total).doubleValue))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
                Text("total")
                    .font(.system(size: 11))
                    .foregroundStyle(.teatowerMuted)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 32)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "storefront.fill").font(.system(size: 10))
                    Text("\(posCount)")
                    Text("·").foregroundStyle(.teatowerMuted)
                    Image(systemName: "globe").font(.system(size: 10))
                    Text("\(onlineCount)")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.teatowerGreen)
                Text("boutique · en ligne")
                    .font(.system(size: 11))
                    .foregroundStyle(.teatowerMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadPurchases() async {
        do {
            purchases = try await supabase.fetchPurchases()
        } catch {
            print("Failed to load purchases: \(error)")
        }
        isLoading = false
    }
}

struct PurchaseRow: View {
    let purchase: Purchase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: purchase.sourceIcon)
                    .foregroundStyle(sourceColor)
                    .frame(width: 28, height: 28)
                    .background(sourceColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(purchase.sourceDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(purchase.orderDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(.teatowerMuted)
                }

                Spacer()

                Text(String(format: "%.2f€", NSDecimalNumber(decimal: purchase.total).doubleValue))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
            }

            if !purchase.items.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(purchase.items.prefix(3).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 6) {
                            Text("\(Int(item.qty))x")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.teatowerBrown)
                                .frame(width: 22, alignment: .trailing)
                            Text(item.name)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if purchase.items.count > 3 {
                        Text("+\(purchase.items.count - 3) autres")
                            .font(.system(size: 11))
                            .foregroundStyle(.teatowerMuted)
                            .padding(.leading, 28)
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 10)
    }

    private var sourceColor: Color {
        switch purchase.source {
        case "pos_waterloo": return .storeWaterloo
        case "pos_namur": return .storeNamur
        case "pos_liege": return .storeLiege
        case "shopify": return .storeOnline
        default: return .teatowerGreen
        }
    }
}
