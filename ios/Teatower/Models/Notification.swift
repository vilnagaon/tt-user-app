import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let email: String
    let title: String
    let body: String
    let type: String
    let data: [String: AnyCodableValue]?
    var isRead: Bool
    let sentAt: Date?
    var readAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, title, body, type, data
        case isRead = "is_read"
        case sentAt = "sent_at"
        case readAt = "read_at"
    }

    var icon: String {
        switch type {
        case "promo": return "tag.fill"
        case "restock": return "arrow.clockwise"
        case "new_arrival": return "sparkles"
        case "badge": return "trophy.fill"
        case "loyalty_tier": return "star.fill"
        case "referral": return "person.2.fill"
        case "journal_reminder": return "book.fill"
        case "system": return "bell.fill"
        default: return "bell.fill"
        }
    }

    var iconColor: String {
        switch type {
        case "promo": return "6D3A05"
        case "badge": return "FFB300"
        case "loyalty_tier": return "FFD700"
        case "new_arrival": return "16393E"
        default: return "16393E"
        }
    }
}
