import SwiftUI

struct ContentView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var isLoading = true
    @State private var needsOnboarding = false

    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if supabase.isAuthenticated {
                MainTabView()
                    .sheet(isPresented: $needsOnboarding) {
                        OnboardingQuizView()
                    }
            } else {
                LoginView()
            }
        }
        .task {
            await supabase.checkSession()
            isLoading = false

            // Check if onboarding needed
            if supabase.isAuthenticated {
                await checkOnboarding()
            }
        }
    }

    private func checkOnboarding() async {
        do {
            if let profile = try await supabase.fetchProfile() {
                let types = profile.teaProfile.favoriteTypes ?? []
                needsOnboarding = types.isEmpty
            } else {
                needsOnboarding = true
            }
        } catch {
            needsOnboarding = false
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.teatowerBg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.teatowerGreen)
                Text("Teatower")
                    .font(.teatowerTitle)
                    .foregroundStyle(.teatowerGreen)
                ProgressView()
                    .tint(.teatowerGreen)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TeaProfileView()
                .tabItem {
                    Label("Profil", systemImage: "leaf.fill")
                }

            PurchaseHistoryView()
                .tabItem {
                    Label("Achats", systemImage: "bag.fill")
                }

            LoyaltyDashboardView()
                .tabItem {
                    Label("Fidélité", systemImage: "star.fill")
                }

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }

            MoreView()
                .tabItem {
                    Label("Plus", systemImage: "ellipsis")
                }
        }
        .tint(.teatowerGreen)
    }
}

struct MoreView: View {
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scanner un produit", systemImage: "barcode.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.teatowerGreen)
                    }
                }

                Section {
                    NavigationLink {
                        BadgesView()
                    } label: {
                        Label("Mes Badges", systemImage: "trophy.fill")
                    }

                    NavigationLink {
                        RecommendationsView()
                    } label: {
                        Label("Recommandations", systemImage: "sparkles")
                    }

                    NavigationLink {
                        NotificationCenterView()
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }

                Section {
                    NavigationLink {
                        StoreLocatorView()
                    } label: {
                        Label("Nos Boutiques", systemImage: "mappin.and.ellipse")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Réglages", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("Plus")
            .fullScreenCover(isPresented: $showScanner) {
                ScanView()
            }
        }
    }
}
