import Foundation

struct JournalEntry: Codable, Identifiable {
    var id: String?
    let email: String?
    var teaName: String
    var sku: String?
    var rating: Int?
    var notes: String?
    var photoUrl: String?
    var brewTempCelsius: Int?
    var brewTimeSeconds: Int?
    var waterAmountMl: Int?
    var teaAmountGrams: Double?
    var mood: [String]?
    var moment: String?
    var isFavorite: Bool
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, sku, rating, notes, mood, moment
        case teaName = "tea_name"
        case photoUrl = "photo_url"
        case brewTempCelsius = "brew_temp_celsius"
        case brewTimeSeconds = "brew_time_seconds"
        case waterAmountMl = "water_amount_ml"
        case teaAmountGrams = "tea_amount_grams"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var ratingStars: String {
        guard let r = rating else { return "" }
        return String(repeating: "★", count: r) + String(repeating: "☆", count: 5 - r)
    }

    var brewSummary: String? {
        var parts: [String] = []
        if let t = brewTempCelsius { parts.append("\(t)°C") }
        if let s = brewTimeSeconds {
            let min = s / 60
            let sec = s % 60
            parts.append(sec > 0 ? "\(min)m\(sec)s" : "\(min) min")
        }
        if let g = teaAmountGrams { parts.append("\(g)g") }
        if let w = waterAmountMl { parts.append("\(w)ml") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    static let moods = ["Relaxant", "Énergisant", "Focus", "Social", "Réconfortant", "Créatif"]
    static let moments = ["Matin", "Après-midi", "Soir", "Weekend", "Travail", "Sport"]
}
