import Foundation

struct AudienceMember: Codable, Identifiable {
    var id: String { email }
    let email: String
    var firstName: String?
    var lastName: String?
    var phone: String?
    var birthDate: Date?
    var language: String?
    var addressStreet: String?
    var addressCity: String?
    var addressZip: String?
    var addressCountry: String?
    var status: MemberStatus
    var sourceShopify: Bool
    var sourceOdoo: Bool
    var sourceMailchimp: Bool
    var sourceApp: Bool
    var preferredStore: StoreId?
    var lifetimeValue: Decimal
    var totalOrders: Int
    var totalOrdersPos: Int
    var totalOrdersOnline: Int
    var avgBasket: Decimal
    var firstPurchaseDate: Date?
    var lastPurchaseDate: Date?
    var lastActivityDate: Date?
    var teaProfile: TeaProfile
    var loyaltyPoints: Int
    var loyaltyTier: String
    var loyaltyPointsLifetime: Int
    var referralCode: String?
    var referralCount: Int
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phone
        case birthDate = "birth_date"
        case language
        case addressStreet = "address_street"
        case addressCity = "address_city"
        case addressZip = "address_zip"
        case addressCountry = "address_country"
        case status
        case sourceShopify = "source_shopify"
        case sourceOdoo = "source_odoo"
        case sourceMailchimp = "source_mailchimp"
        case sourceApp = "source_app"
        case preferredStore = "preferred_store"
        case lifetimeValue = "lifetime_value"
        case totalOrders = "total_orders"
        case totalOrdersPos = "total_orders_pos"
        case totalOrdersOnline = "total_orders_online"
        case avgBasket = "avg_basket"
        case firstPurchaseDate = "first_purchase_date"
        case lastPurchaseDate = "last_purchase_date"
        case lastActivityDate = "last_activity_date"
        case teaProfile = "tea_profile"
        case loyaltyPoints = "loyalty_points"
        case loyaltyTier = "loyalty_tier"
        case loyaltyPointsLifetime = "loyalty_points_lifetime"
        case referralCode = "referral_code"
        case referralCount = "referral_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }

    var sourcesDescription: String {
        var sources: [String] = []
        if sourceShopify { sources.append("Shopify") }
        if sourceOdoo { sources.append("Boutique") }
        if sourceMailchimp { sources.append("Newsletter") }
        if sourceApp { sources.append("App") }
        return sources.joined(separator: " · ")
    }

    var isMultiChannel: Bool {
        (sourceShopify ? 1 : 0) + (sourceOdoo ? 1 : 0) > 1
    }
}

enum MemberStatus: String, Codable {
    case subscribed
    case unsubscribed
    case cleaned
    case transactional
    case pending
}

enum StoreId: String, Codable {
    case waterloo
    case namur
    case liege
    case online

    var displayName: String {
        switch self {
        case .waterloo: return "Waterloo"
        case .namur: return "Namur"
        case .liege: return "Liège"
        case .online: return "En ligne"
        }
    }
}

struct TeaProfile: Codable {
    var favoriteTypes: [String]?
    var favoriteProducts: [String]?
    var brewingMethod: String?
    var frequency: String?
    var taste: TastePreferences?
    var caffeinePreference: String?
    var discoveryNotes: String?

    enum CodingKeys: String, CodingKey {
        case favoriteTypes = "favorite_types"
        case favoriteProducts = "favorite_products"
        case brewingMethod = "brewing_method"
        case frequency
        case taste
        case caffeinePreference = "caffeine_preference"
        case discoveryNotes = "discovery_notes"
    }
}

struct TastePreferences: Codable {
    var sweet: Int?
    var bitter: Int?
    var floral: Int?
    var spicy: Int?
    var fruity: Int?
    var earthy: Int?
}
