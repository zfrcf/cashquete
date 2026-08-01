import SwiftUI

enum Theme {
    static let accent = Color(red: 0.42, green: 0.55, blue: 1.0)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.25)
    static let success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.40)
    static let cardBackground = Color(.secondarySystemBackground)
    static let background = Color(.systemBackground)

    static let heroGradient = LinearGradient(
        colors: [accent, Color(red: 0.55, green: 0.35, blue: 0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
