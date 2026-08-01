import SwiftUI

struct MemoryGameView: View {
    private struct Card: Identifiable {
        let id = UUID()
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    @State private var cards: [Card] = []
    @State private var firstIndex: Int?
    @State private var moves = 0
    @State private var finished = false
    @State private var busy = false

    // Moins de coups = meilleur score (6 coups parfaits = 100 pts)
    private var score: Int { max(10, 100 - (moves - 6) * 6) }

    var body: some View {
        VStack(spacing: 16) {
            if finished {
                QuestResultView(gameId: "memory", score: score, onReplay: start)
            } else {
                Text("Moves: \(moves)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(cards.indices, id: \.self) { i in
                        cardView(i)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if cards.isEmpty { start() } }
    }

    private func cardView(_ i: Int) -> some View {
        let card = cards[i]
        let revealed = card.isFaceUp || card.isMatched
        return Button {
            flip(i)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(revealed ? Theme.cardBackground : Theme.accent)
                if revealed {
                    Text(card.emoji).font(.system(size: 34))
                }
            }
            .frame(height: 84)
            .rotation3DEffect(.degrees(revealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(duration: 0.35), value: revealed)
            .opacity(card.isMatched ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(busy || revealed)
    }

    private func start() {
        let emojis = ["🍒", "💎", "⭐️", "🎲", "🚀", "🏆"]
        cards = (emojis + emojis).shuffled().map { Card(emoji: $0) }
        firstIndex = nil
        moves = 0
        finished = false
        busy = false
    }

    private func flip(_ i: Int) {
        cards[i].isFaceUp = true
        guard let f = firstIndex else {
            firstIndex = i
            return
        }
        moves += 1
        busy = true
        let matched = cards[f].emoji == cards[i].emoji
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if matched {
                cards[f].isMatched = true
                cards[i].isMatched = true
            } else {
                cards[f].isFaceUp = false
                cards[i].isFaceUp = false
            }
            firstIndex = nil
            busy = false
            if cards.allSatisfy(\.isMatched) { finished = true }
        }
    }
}
