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
                    Label("Mon Profil", systemImage: "leaf.fill")
                }

            PurchaseHistoryView()
                .tabItem {
                    Label("Mes Achats", systemImage: "bag.fill")
                }

            BadgesView()
                .tabItem {
                    Label("Badges", systemImage: "trophy.fill")
                }

            RecommendationsView()
                .tabItem {
                    Label("Découvrir", systemImage: "sparkles")
                }

            StoreLocatorView()
                .tabItem {
                    Label("Boutiques", systemImage: "mappin.and.ellipse")
                }

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
        }
        .tint(.teatowerGreen)
    }
}
