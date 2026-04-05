import SwiftUI
import Supabase

struct ContentView: View {
    @Environment(\.supabaseClient) private var supabase
    @State private var session: Session?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                SplashView()
            } else if let session {
                MainTabView(userEmail: session.user.email ?? "")
            } else {
                LoginView()
            }
        }
        .task {
            await checkSession()
        }
    }

    private func checkSession() async {
        do {
            session = try await supabase?.auth.session
        } catch {
            session = nil
        }
        isLoading = false

        // Listen for auth changes
        guard let supabase else { return }
        for await (event, session) in supabase.auth.authStateChanges {
            if event == .signedIn {
                self.session = session
            } else if event == .signedOut {
                self.session = nil
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.teatowerBg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("teatower-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                ProgressView()
                    .tint(.teatowerGreen)
            }
        }
    }
}

struct MainTabView: View {
    let userEmail: String

    var body: some View {
        TabView {
            TeaProfileView(email: userEmail)
                .tabItem {
                    Label("Mon Profil", systemImage: "leaf.fill")
                }

            PurchaseHistoryView(email: userEmail)
                .tabItem {
                    Label("Mes Achats", systemImage: "bag.fill")
                }

            RecommendationsView(email: userEmail)
                .tabItem {
                    Label("Découvrir", systemImage: "sparkles")
                }

            StoreLocatorView()
                .tabItem {
                    Label("Boutiques", systemImage: "mappin.and.ellipse")
                }
        }
        .tint(.teatowerGreen)
    }
}
