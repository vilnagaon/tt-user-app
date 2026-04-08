import SwiftUI

struct LoyaltyDashboardView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var member: AudienceMember?
    @State private var transactions: [LoyaltyTransaction] = []
    @State private var rewards: [LoyaltyReward] = []
    @State private var isLoading = true
    @State private var showRewardsShop = false

    private var tier: LoyaltyTier {
        LoyaltyTier(rawValue: member?.loyaltyTier ?? "bronze") ?? .bronze
    }
    private var points: Int { member?.loyaltyPoints ?? 0 }
    private var lifetimePoints: Int { member?.loyaltyPointsLifetime ?? 0 }

    private var progressToNext: Double {
        guard let next = tier.nextTierPoints else { return 1.0 }
        let current = tier.pointsRequired
        let range = next - current
        guard range > 0 else { return 1.0 }
        return min(1.0, Double(lifetimePoints - current) / Double(range))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView().padding(48)
                } else {
                    VStack(spacing: 20) {
                        tierCard
                        pointsCard
                        rewardsPreview
                        recentTransactions
                    }
                    .padding()
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Fidélité")
            .refreshable { await loadData() }
            .sheet(isPresented: $showRewardsShop) {
                RewardsShopView(points: points, rewards: rewards)
            }
        }
        .task { await loadData() }
    }

    // MARK: - Tier Card

    private var tierCard: some View {
        VStack(spacing: 16) {
            // Tier badge
            ZStack {
                Circle()
                    .fill(tierGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: tierColor.opacity(0.3), radius: 12)
                Text(tier.emoji)
                    .font(.system(size: 44))
            }

            Text("Statut \(tier.displayName)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tierColor)

            // Progress to next tier
            if let next = tier.nextTier {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.teatowerBg)
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(tierGradient)
                                .frame(width: geo.size.width * progressToNext, height: 12)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Text("\(lifetimePoints) pts")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(tierColor)
                        Spacer()
                        Text("\(next.pointsRequired) pts pour \(next.emoji) \(next.displayName)")
                            .font(.system(size: 11))
                            .foregroundStyle(.teatowerMuted)
                    }
                }
            } else {
                Text("Niveau maximum atteint")
                    .font(.teatowerCaption)
                    .foregroundStyle(.teatowerBrown)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Points Card

    private var pointsCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("\(points)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.teatowerGreen)
                Text("points disponibles")
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 48)

            VStack(spacing: 4) {
                Text("\(lifetimePoints)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.teatowerBrown)
                Text("points gagnés au total")
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Rewards Preview

    private var rewardsPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Récompenses", systemImage: "gift.fill")
                    .font(.teatowerHeading)
                    .foregroundStyle(.teatowerGreen)
                Spacer()
                Button("Voir tout") { showRewardsShop = true }
                    .font(.teatowerCaption)
                    .foregroundStyle(.teatowerBrown)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(rewards.prefix(4)) { reward in
                        rewardMiniCard(reward)
                    }
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func rewardMiniCard(_ reward: LoyaltyReward) -> some View {
        let canAfford = points >= reward.pointsCost
        return VStack(spacing: 8) {
            Text(reward.emoji)
                .font(.system(size: 28))
            Text(reward.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("\(reward.pointsCost) pts")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(canAfford ? .teatowerGreen : .teatowerMuted)
        }
        .frame(width: 110)
        .padding(12)
        .background(canAfford ? Color.teatowerGreen.opacity(0.05) : Color.teatowerBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canAfford ? Color.teatowerGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .opacity(canAfford ? 1 : 0.6)
    }

    // MARK: - Transactions

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Historique de points", systemImage: "clock.arrow.circlepath")
                .font(.teatowerHeading)
                .foregroundStyle(.teatowerGreen)

            if transactions.isEmpty {
                Text("Vos prochains points apparaîtront ici.")
                    .font(.teatowerBody)
                    .foregroundStyle(.teatowerMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(transactions.prefix(10)) { tx in
                    HStack {
                        Image(systemName: tx.isEarned ? "plus.circle.fill" : "minus.circle.fill")
                            .foregroundStyle(tx.isEarned ? .green : .red)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.description ?? tx.source)
                                .font(.system(size: 13))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(tx.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                .font(.system(size: 11))
                                .foregroundStyle(.teatowerMuted)
                        }
                        Spacer()
                        Text("\(tx.isEarned ? "+" : "")\(tx.points)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(tx.isEarned ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Styling

    private var tierColor: Color {
        switch tier {
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "9E9E9E")
        case .gold: return Color(hex: "FFB300")
        }
    }

    private var tierGradient: LinearGradient {
        switch tier {
        case .bronze: return LinearGradient(colors: [Color(hex: "CD7F32"), Color(hex: "A0522D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .silver: return LinearGradient(colors: [Color(hex: "C0C0C0"), Color(hex: "9E9E9E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold: return LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFB300")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: - Data

    private func loadData() async {
        do {
            member = try await supabase.fetchProfile()
            transactions = try await supabase.client
                .from("loyalty_transactions")
                .select()
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            rewards = try await supabase.client
                .from("loyalty_rewards")
                .select()
                .eq("is_active", value: true)
                .order("sort_order")
                .execute()
                .value
        } catch {
            print("Loyalty load failed: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Rewards Shop

struct RewardsShopView: View {
    let points: Int
    let rewards: [LoyaltyReward]
    @Environment(SupabaseManager.self) private var supabase
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReward: LoyaltyReward?
    @State private var isRedeeming = false
    @State private var redeemed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Points balance header
                    HStack {
                        Text("\(points) points disponibles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.teatowerGreen)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ForEach(rewards) { reward in
                        rewardCard(reward)
                    }
                }
                .padding()
            }
            .background(Color.teatowerBg)
            .navigationTitle("Récompenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert("Échanger ?", isPresented: Binding(
                get: { selectedReward != nil && !redeemed },
                set: { if !$0 { selectedReward = nil } }
            )) {
                Button("Annuler", role: .cancel) { selectedReward = nil }
                Button("Échanger \(selectedReward?.pointsCost ?? 0) pts") {
                    Task { await redeem() }
                }
            } message: {
                Text("Vous allez échanger \(selectedReward?.pointsCost ?? 0) points contre : \(selectedReward?.name ?? "")")
            }
        }
    }

    private func rewardCard(_ reward: LoyaltyReward) -> some View {
        let canAfford = points >= reward.pointsCost
        return HStack(spacing: 16) {
            Text(reward.emoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(canAfford ? Color.teatowerGreen.opacity(0.08) : Color.teatowerBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.system(size: 15, weight: .semibold))
                Text(reward.description ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                selectedReward = reward
            } label: {
                Text("\(reward.pointsCost)")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.teatowerGreen : Color.gray.opacity(0.2))
                    .foregroundColor(canAfford ? .white : Color.teatowerMuted)
                    .clipShape(Capsule())
            }
            .disabled(!canAfford)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(canAfford ? 1 : 0.7)
    }

    private func redeem() async {
        guard let reward = selectedReward else { return }
        isRedeeming = true
        do {
            try await supabase.client.rpc("redeem_reward", params: [
                "target_email": supabase.currentEmail ?? "",
                "target_reward_id": reward.id,
            ]).execute()
            redeemed = true
            try? await Task.sleep(for: .seconds(1))
            dismiss()
        } catch {
            print("Redeem failed: \(error)")
        }
        isRedeeming = false
    }
}
