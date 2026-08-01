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

                    GameCard(title: "Quiz Math", subtitle: "10 questions",
                             icon: "brain.head.profile", color: Theme.accent) {
                        QuizGameView()
                    }
                    GameCard(title: "Memory", subtitle: "6 pairs",
                             icon: "square.grid.3x3.fill", color: .purple) {
                        MemoryGameView()
                    }
                    GameCard(title: "Reflex", subtitle: "5 rounds",
                             icon: "bolt.fill", color: Theme.gold) {
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
    let color: Color
    @ViewBuilder let destination: () -> Destination
    @EnvironmentObject private var ads: AdManager

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.18))
                    .foregroundStyle(color)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    Text("Up to 100 pts per quest")
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
