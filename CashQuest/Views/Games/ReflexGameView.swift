import SwiftUI

struct ReflexGameView: View {
    private enum Phase {
        case idle, waiting, go, tooSoon, done
    }

    @State private var phase: Phase = .idle
    @State private var round = 0
    @State private var times: [Int] = []
    @State private var goDate = Date()
    @State private var workItem: DispatchWorkItem?

    // 200 ms de moyenne ≈ 100 pts, chaque 5 ms de plus enlève 1 pt
    private var score: Int {
        guard !times.isEmpty else { return 0 }
        let avg = times.reduce(0, +) / times.count
        return max(10, min(100, 100 - (avg - 200) / 5))
    }

    var body: some View {
        VStack(spacing: 20) {
            if phase == .done {
                QuestResultView(gameId: "reflex", score: score, onReplay: reset)
            } else {
                Text("Round \(min(round + 1, 5))/5")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                tapZone
                if let last = times.last, phase == .idle {
                    Text("\(last) ms")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.gold)
                        .transition(.scale.combined(with: .opacity))
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Reflex")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: times.count)
        .onDisappear { workItem?.cancel() }
    }

    private var tapZone: some View {
        Button(action: tap) {
            RoundedRectangle(cornerRadius: 24)
                .fill(phase == .go ? Theme.success : (phase == .tooSoon ? Theme.danger : Theme.accent))
                .frame(height: 320)
                .overlay {
                    Text(label)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
                .animation(.easeInOut(duration: 0.15), value: phase == .go)
        }
        .buttonStyle(.plain)
    }

    private var label: LocalizedStringKey {
        switch phase {
        case .idle: "Tap to start"
        case .waiting: "Wait for green…"
        case .go: "TAP!"
        case .tooSoon: "Too soon!"
        case .done: ""
        }
    }

    private func tap() {
        switch phase {
        case .idle, .tooSoon:
            phase = .waiting
            let item = DispatchWorkItem {
                goDate = Date()
                phase = .go
            }
            workItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...3.0), execute: item)
        case .waiting:
            workItem?.cancel()
            phase = .tooSoon
        case .go:
            times.append(Int(Date().timeIntervalSince(goDate) * 1000))
            round += 1
            phase = round >= 5 ? .done : .idle
        case .done:
            break
        }
    }

    private func reset() {
        phase = .idle
        round = 0
        times = []
    }
}
