import Foundation

struct LoyaltyTransaction: Codable, Identifiable {
    let id: String
    let email: String
    let points: Int
    let source: String
    let sourceRef: String?
    let description: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, points, source, description
        case sourceRef = "source_ref"
        case createdAt = "created_at"
    }

    var isEarned: Bool { points > 0 }
}

struct LoyaltyReward: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let emoji: String
    let pointsCost: Int
    let rewardType: String
    let rewardValue: [String: AnyCodableValue]?
    let isActive: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, emoji
        case pointsCost = "points_cost"
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case isActive = "is_active"
        case sortOrder = "sort_order"
    }
}

struct LoyaltyRedemption: Codable, Identifiable {
    let id: String
    let email: String
    let rewardId: String
    let pointsSpent: Int
    let shopifyDiscountCode: String?
    let status: String
    let createdAt: Date?
    let expiresAt: Date?
    let usedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, status
        case rewardId = "reward_id"
        case pointsSpent = "points_spent"
        case shopifyDiscountCode = "shopify_discount_code"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case usedAt = "used_at"
    }
}

enum LoyaltyTier: String, CaseIterable {
    case bronze, silver, gold

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        }
    }

    var emoji: String {
        switch self {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        }
    }

    var nextTier: LoyaltyTier? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return nil
        }
    }

    var pointsRequired: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 500
        case .gold: return 1500
        }
    }

    var nextTierPoints: Int? {
        nextTier?.pointsRequired
    }
}

// Helper for decoding JSONB values
enum AnyCodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) { self = .int(v) }
        else if let v = try? container.decode(Double.self) { self = .double(v) }
        else if let v = try? container.decode(Bool.self) { self = .bool(v) }
        else if let v = try? container.decode(String.self) { self = .string(v) }
        else { self = .string("") }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        }
    }
}
