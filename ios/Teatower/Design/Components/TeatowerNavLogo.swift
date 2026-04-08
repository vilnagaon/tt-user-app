import SwiftUI

/// Small Teatower logo for navigation bar use. Appears as a centered inline toolbar item.
struct TeatowerNavLogo: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            AsyncImage(url: URL(string: "https://teatower.com/cdn/shop/files/Teatower_-_logo_-BELGIAN_TEA_HOUSE.png")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.teatowerGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                default:
                    Text("TEATOWER")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.teatowerGreen)
                }
            }
        }
    }
}

/// View modifier to add Teatower branding to any NavigationStack
extension View {
    func teatowerBranded() -> some View {
        self.toolbar { TeatowerNavLogo() }
    }
}
