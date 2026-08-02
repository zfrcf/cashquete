import SwiftUI

struct GamesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Choose a game")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GameCard(title: "2048", subtitle: "Merge the tiles",
                             icon: "square.grid.2x2.fill",
                             colors: [.orange, Theme.gold]) {
                        Game2048View()
                    }
                    GameCard(title: "Quiz Math", subtitle: "Beat the clock",
                             icon: "brain.head.profile",
                             colors: [Theme.accent, .cyan]) {
                        QuizGameView()
                    }
                    GameCard(title: "Memory", subtitle: "8 pairs, be fast",
                             icon: "square.grid.3x3.fill",
                             colors: [.purple, .pink]) {
                        MemoryGameView()
                    }
                    GameCard(title: "Tap Rush", subtitle: "30 seconds of frenzy",
                             icon: "bolt.fill",
                             colors: [Theme.danger, .orange]) {
                        ReflexGameView()
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Games")
        }
    }
}

struct GameCard<Destination: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let colors: [Color]
    @ViewBuilder let destination: () -> Destination
    @EnvironmentObject private var ads: AdManager

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: colors,
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: colors[0].opacity(0.45), radius: 8, y: 4)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    Label("Up to 100 pts per quest", systemImage: "dollarsign.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.gold)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { ads.registerTap() })
    }
}
