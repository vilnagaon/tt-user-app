import SwiftUI

/// Teatower logo loaded from CDN. Use in splash, login, and anywhere the brand logo is needed.
struct TeatowerLogo: View {
    var width: CGFloat = 160
    var onDark: Bool = false

    private let logoURL = "https://teatower.com/cdn/shop/files/Teatower_-_logo_-BELGIAN_TEA_HOUSE.png"

    var body: some View {
        AsyncImage(url: URL(string: logoURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
            case .failure:
                fallbackLogo
            case .empty:
                fallbackLogo
                    .redacted(reason: .placeholder)
            @unknown default:
                fallbackLogo
            }
        }
    }

    private var fallbackLogo: some View {
        HStack(spacing: 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: width * 0.2))
            Text("TEATOWER")
                .font(.system(size: width * 0.12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(onDark ? .white : .teatowerGreen)
    }
}
