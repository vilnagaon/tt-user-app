import Foundation

struct Product: Codable, Identifiable {
    var id: String { sku }
    let sku: String
    let shopifyProductId: String?
    let shopifyVariantId: String?
    let name: String
    let category: String?
    let weightGrams: Int?
    let priceEur: Decimal?
    let barcode: String?
    let imageUrl: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case sku, name, category, barcode
        case shopifyProductId = "shopify_product_id"
        case shopifyVariantId = "shopify_variant_id"
        case weightGrams = "weight_grams"
        case priceEur = "price_eur"
        case imageUrl = "image_url"
        case isActive = "is_active"
    }
}

struct Favorite: Codable {
    let email: String
    let sku: String
    let addedAt: Date?

    enum CodingKeys: String, CodingKey {
        case email, sku
        case addedAt = "added_at"
    }
}
