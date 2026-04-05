import SwiftUI

struct PurchaseHistoryView: View {
    let email: String
    @State private var purchases: [Purchase] = []
    @State private var isLoading = true
    @Environment(\.supabaseClient) private var supabase

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().padding(48)
                } else if purchases.isEmpty {
                    ContentUnavailableView(
                        "Pas encore d'achats",
                        systemImage: "bag",
                        description: Text("Vos achats en boutique et en ligne apparaîtront ici.")
                    )
                } else {
                    List(purchases) { purchase in
                        PurchaseRow(purchase: purchase)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Mes Achats")
        }
        .task { await loadPurchases() }
    }

    private func loadPurchases() async {
        guard let supabase else { return }
        do {
            purchases = try await supabase
                .from("purchases")
                .select()
                .eq("email", value: email)
                .order("order_date", ascending: false)
                .limit(100)
                .execute()
                .value
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
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(purchase.sourceDisplayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.teatowerGreen)

                    Text(purchase.orderDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(.teatowerMuted)
                }

                Spacer()

                Text("\(purchase.total)€")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
            }

            if !purchase.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(purchase.items.prefix(3), id: \.name) { item in
                        HStack {
                            Text("\(Int(item.qty))x")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.teatowerBrown)
                                .frame(width: 24)
                            Text(item.name)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if purchase.items.count > 3 {
                        Text("+\(purchase.items.count - 3) autres articles")
                            .font(.system(size: 11))
                            .foregroundStyle(.teatowerMuted)
                    }
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
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
