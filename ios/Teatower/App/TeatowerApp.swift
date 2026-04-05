import SwiftUI
import Supabase

@main
struct TeatowerApp: App {
    @State private var supabase = SupabaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(supabase)
                .onOpenURL { url in
                    Task { await supabase.handleDeepLink(url) }
                }
        }
    }
}
