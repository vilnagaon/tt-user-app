import SwiftUI

extension Color {
    static let teatowerGreen = Color(hex: "16393E")
    static let teatowerBrown = Color(hex: "6D3A05")
    static let teatowerBg = Color(hex: "F8F5F0")
    static let teatowerCard = Color.white
    static let teatowerBorder = Color(hex: "E8E5DF")
    static let teatowerMuted = Color(hex: "7A7A7A")

    // Store colors
    static let storeWaterloo = Color(hex: "2D5016")
    static let storeNamur = Color(hex: "8B4513")
    static let storeLiege = Color(hex: "1A5276")
    static let storeOnline = Color(hex: "96BF48")
}

// Allow .teatowerGreen etc. in foregroundStyle() and other ShapeStyle contexts
extension ShapeStyle where Self == Color {
    static var teatowerGreen: Color { .teatowerGreen }
    static var teatowerBrown: Color { .teatowerBrown }
    static var teatowerBg: Color { .teatowerBg }
    static var teatowerCard: Color { .teatowerCard }
    static var teatowerBorder: Color { .teatowerBorder }
    static var teatowerMuted: Color { .teatowerMuted }
    static var storeWaterloo: Color { .storeWaterloo }
    static var storeNamur: Color { .storeNamur }
    static var storeLiege: Color { .storeLiege }
    static var storeOnline: Color { .storeOnline }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font {
    static let teatowerTitle = Font.system(size: 28, weight: .bold, design: .serif)
    static let teatowerHeading = Font.system(size: 20, weight: .semibold)
    static let teatowerBody = Font.system(size: 15)
    static let teatowerCaption = Font.system(size: 12, weight: .medium)
    static let teatowerKPI = Font.system(size: 32, weight: .bold)
}
