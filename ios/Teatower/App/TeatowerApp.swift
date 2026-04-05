import SwiftUI
import Supabase

@main
struct TeatowerApp: App {
    static let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
        supabaseKey: "YOUR_ANON_KEY"
    )

    @State private var isAuthenticated = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabaseClient, TeatowerApp.supabase)
        }
    }
}

// Environment key for Supabase client
private struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}
