import Foundation

struct BadgeDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let category: String
    let tier: String
    let requirement: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, emoji, category, tier, requirement
        case sortOrder = "sort_order"
    }
}

struct BadgeEarned: Codable {
    let email: String
    let badgeId: String
    let earnedAt: Date?
    let progress: Int

    enum CodingKeys: String, CodingKey {
        case email
        case badgeId = "badge_id"
        case earnedAt = "earned_at"
        case progress
    }
}

struct BadgeWithStatus: Identifiable {
    let definition: BadgeDefinition
    let earned: Bool
    let earnedAt: Date?

    var id: String { definition.id }
}
