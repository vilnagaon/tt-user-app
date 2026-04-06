import Foundation
import UserNotifications
import UIKit

@Observable
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private(set) var isAuthorized = false
    private(set) var deviceToken: String?
    private(set) var unreadCount = 0

    override private init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            print("Push permission error: \(error)")
            return false
        }
    }

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Token

    func didRegisterToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token

        // Save to Supabase
        Task {
            guard let email = SupabaseManager.shared.currentEmail else { return }
            try? await SupabaseManager.shared.client
                .from("audience")
                .update(["apns_device_token": token, "push_enabled": true])
                .eq("email", value: email)
                .execute()
        }
    }

    // MARK: - Unread Count

    func refreshUnreadCount() async {
        guard let email = SupabaseManager.shared.currentEmail else { return }
        do {
            let result: [AppNotification] = try await SupabaseManager.shared.client
                .from("notifications")
                .select()
                .eq("email", value: email)
                .eq("is_read", value: false)
                .execute()
                .value
            unreadCount = result.count
        } catch {
            print("Unread count error: \(error)")
        }
    }

    // MARK: - Mark Read

    func markAsRead(_ notificationId: String) async {
        try? await SupabaseManager.shared.client
            .from("notifications")
            .update(["is_read": true, "read_at": Date().ISO8601Format()])
            .eq("id", value: notificationId)
            .execute()
        await refreshUnreadCount()
    }

    func markAllRead() async {
        guard let email = SupabaseManager.shared.currentEmail else { return }
        try? await SupabaseManager.shared.client
            .from("notifications")
            .update(["is_read": true, "read_at": Date().ISO8601Format()])
            .eq("email", value: email)
            .eq("is_read", value: false)
            .execute()
        unreadCount = 0
    }
}
