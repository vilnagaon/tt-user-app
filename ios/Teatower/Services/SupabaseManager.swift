import Foundation
import Supabase

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private(set) var currentUser: User?
    private(set) var currentEmail: String?
    private(set) var isAuthenticated = false

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://lmqzufwcoyojsyrvkegh.supabase.co")!,
            supabaseKey: "sb_publishable_DMLluj2Kcrk9mBAwkuurFw_O0_VVx5Q"
        )
    }

    // MARK: - Auth

    func sendMagicLink(email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email.lowercased().trimmingCharacters(in: .whitespaces),
            redirectTo: URL(string: "teatower://login-callback")
        )
    }

    func checkSession() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            currentEmail = session.user.email
            isAuthenticated = true
        } catch {
            currentUser = nil
            currentEmail = nil
            isAuthenticated = false
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        currentUser = nil
        currentEmail = nil
        isAuthenticated = false
    }

    func handleDeepLink(_ url: URL) async {
        do {
            try await client.auth.session(from: url)
            await checkSession()
        } catch {
            print("Deep link auth error: \(error)")
        }
    }

    // MARK: - Audience

    func fetchProfile() async throws -> AudienceMember? {
        guard let email = currentEmail else { return nil }
        return try await client
            .from("audience")
            .select()
            .eq("email", value: email)
            .single()
            .execute()
            .value
    }

    func updateTeaProfile(_ profile: TeaProfile) async throws {
        guard let email = currentEmail else { return }
        try await client
            .from("audience")
            .update(["tea_profile": profile, "updated_at": Date().ISO8601Format()])
            .eq("email", value: email)
            .execute()
    }

    // MARK: - Purchases

    func fetchPurchases(limit: Int = 100) async throws -> [Purchase] {
        guard let email = currentEmail else { return [] }
        return try await client
            .from("purchases")
            .select()
            .eq("email", value: email)
            .order("order_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Tags

    func fetchTags() async throws -> [String] {
        guard let email = currentEmail else { return [] }
        let result: [[String: String]] = try await client
            .from("tags")
            .select("tag")
            .eq("email", value: email)
            .execute()
            .value
        return result.compactMap { $0["tag"] }
    }
}
