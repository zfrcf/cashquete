import SwiftUI

/// Memory 4×4 chronométré : 8 paires, moins de coups et moins de temps = plus de points.
struct MemoryGameView: View {
    private struct Card: Identifiable {
        let id = UUID()
        let emoji: String
        var isFaceUp = false
        var isMatched = false
    }

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var cards: [Card] = []
    @State private var firstIndex: Int?
    @State private var moves = 0
    @State private var seconds = 0
    @State private var finished = false
    @State private var busy = false

    // 8 coups parfaits + rapide = ~100 pts
    private var score: Int { max(10, 140 - max(0, moves - 8) * 4 - seconds) }

    var body: some View {
        VStack(spacing: 14) {
            if finished {
                QuestResultView(gameId: "memory", score: score, onReplay: start)
            } else {
                HStack {
                    Label("\(moves)", systemImage: "hand.tap.fill")
                    Spacer()
                    Label("\(seconds)s", systemImage: "stopwatch.fill")
                        .foregroundStyle(seconds > 45 ? Theme.danger : Theme.gold)
                }
                .font(.headline)
                .monospacedDigit()

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
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
        .onReceive(clock) { _ in
            if !finished && !cards.isEmpty { seconds += 1 }
        }
    }

    private func cardView(_ i: Int) -> some View {
        let card = cards[i]
        let revealed = card.isFaceUp || card.isMatched
        return Button {
            flip(i)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(revealed ? AnyShapeStyle(Theme.cardBackground) : AnyShapeStyle(Theme.heroGradient))
                if revealed {
                    Text(card.emoji).font(.system(size: 30))
                } else {
                    Image(systemName: "questionmark")
                        .font(.title3.bold())
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(height: 76)
            .rotation3DEffect(.degrees(revealed ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(duration: 0.35), value: revealed)
            .opacity(card.isMatched ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(busy || revealed)
    }

    private func start() {
        let emojis = ["🍒", "💎", "⭐️", "🎲", "🚀", "🏆", "🍀", "🔥"]
        cards = (emojis + emojis).shuffled().map { Card(emoji: $0) }
        firstIndex = nil
        moves = 0
        seconds = 0
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
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
