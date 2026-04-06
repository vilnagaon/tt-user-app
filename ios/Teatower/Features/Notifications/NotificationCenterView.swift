import SwiftUI

struct NotificationCenterView: View {
    @Environment(SupabaseManager.self) private var supabase
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true
    @State private var pushService = PushNotificationService.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().padding(48)
                } else if notifications.isEmpty {
                    ContentUnavailableView(
                        "Pas de notifications",
                        systemImage: "bell.slash",
                        description: Text("Vos alertes, badges et promos apparaîtront ici.")
                    )
                } else {
                    List {
                        if !pushService.isAuthorized {
                            enablePushBanner
                        }

                        ForEach(notifications) { notif in
                            NotificationRow(notification: notif)
                                .onTapGesture {
                                    Task { await pushService.markAsRead(notif.id) }
                                }
                                .listRowBackground(notif.isRead ? Color.clear : Color.teatowerGreen.opacity(0.04))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.teatowerBg)
            .navigationTitle("Notifications")
            .toolbar {
                if !notifications.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Tout lire") {
                            Task {
                                await pushService.markAllRead()
                                for i in notifications.indices {
                                    notifications[i].isRead = true
                                }
                            }
                        }
                        .font(.teatowerCaption)
                        .foregroundStyle(.teatowerBrown)
                    }
                }
            }
            .refreshable { await loadNotifications() }
        }
        .task { await loadNotifications() }
    }

    private var enablePushBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 24))
                .foregroundStyle(.teatowerBrown)

            VStack(alignment: .leading, spacing: 2) {
                Text("Activez les notifications")
                    .font(.system(size: 14, weight: .semibold))
                Text("Recevez vos alertes de badges, promos et réappro en temps réel.")
                    .font(.system(size: 12))
                    .foregroundStyle(.teatowerMuted)
            }

            Spacer()

            Button("Activer") {
                Task { await pushService.requestPermission() }
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.teatowerGreen)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(12)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.teatowerGreen.opacity(0.05))
    }

    private func loadNotifications() async {
        do {
            notifications = try await supabase.client
                .from("notifications")
                .select()
                .order("sent_at", ascending: false)
                .limit(50)
                .execute()
                .value
            await pushService.refreshUnreadCount()
        } catch {
            print("Notifications load failed: \(error)")
        }
        isLoading = false
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: notification.icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: notification.iconColor))
                .frame(width: 36, height: 36)
                .background(Color(hex: notification.iconColor).opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.system(size: 14, weight: notification.isRead ? .regular : .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(timeAgo(notification.sentAt))
                        .font(.system(size: 11))
                        .foregroundStyle(.teatowerMuted)
                }

                Text(notification.body)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if !notification.isRead {
                Circle()
                    .fill(Color.teatowerGreen)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(_ date: Date?) -> String {
        guard let date else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))min" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))j" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - Bell Badge (for navigation bar)

struct NotificationBellButton: View {
    @State private var pushService = PushNotificationService.shared
    @State private var showNotifications = false

    var body: some View {
        Button { showNotifications = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.teatowerGreen)

                if pushService.unreadCount > 0 {
                    Text("\(min(pushService.unreadCount, 99))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -6)
                }
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationCenterView()
        }
        .task { await pushService.refreshUnreadCount() }
    }
}
