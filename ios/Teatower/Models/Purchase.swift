import Foundation

struct Purchase: Codable, Identifiable {
    let id: String
    let email: String
    let source: String
    let sourceOrderId: String?
    let orderDate: Date
    let total: Decimal
    let currency: String
    let items: [PurchaseItem]
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, source, currency, items
        case sourceOrderId = "source_order_id"
        case orderDate = "order_date"
        case total
        case createdAt = "created_at"
    }

    var sourceDisplayName: String {
        switch source {
        case "shopify": return "En ligne"
        case "pos_waterloo": return "Waterloo"
        case "pos_namur": return "Namur"
        case "pos_liege": return "Liège"
        default: return source
        }
    }

    var sourceIcon: String {
        switch source {
        case "shopify": return "globe"
        case "pos_waterloo", "pos_namur", "pos_liege": return "storefront.fill"
        default: return "bag.fill"
        }
    }
}

struct PurchaseItem: Codable {
    let sku: String?
    let name: String
    let qty: Double
    let price: Decimal
}
