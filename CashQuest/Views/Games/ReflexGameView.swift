import SwiftUI

/// Tap Rush : 30 secondes, des cibles apparaissent au hasard — touche-les avant
/// qu'elles disparaissent. Chaque cible touchée rapporte, chaque ratée pénalise.
struct ReflexGameView: View {
    private struct Target: Identifiable, Equatable {
        let id = UUID()
        let pos: CGPoint
        let size: CGFloat
        let color: Color
    }

    private let duration = 30
    private let countdown = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var started = false
    @State private var finished = false
    @State private var timeLeft = 30
    @State private var hits = 0
    @State private var misses = 0
    @State private var target: Target?

    private var score: Int { max(0, hits * 4 - misses * 2) }

    var body: some View {
        VStack(spacing: 12) {
            if finished {
                QuestResultView(gameId: "reflex", score: score, onReplay: reset)
            } else {
                HStack {
                    Label("\(hits)", systemImage: "target")
                        .foregroundStyle(Theme.success)
                    Spacer()
                    Label("\(timeLeft)s", systemImage: "stopwatch.fill")
                        .foregroundStyle(timeLeft <= 5 ? Theme.danger : Theme.gold)
                }
                .font(.headline)
                .monospacedDigit()

                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.cardBackground)

                        if !started {
                            Button {
                                started = true
                                spawn(in: geo.size)
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(Theme.gold)
                                    Text("Tap to start").font(.headline)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if let t = target {
                            Circle()
                                .fill(t.color.gradient)
                                .frame(width: t.size, height: t.size)
                                .overlay {
                                    Circle()
                                        .stroke(.white.opacity(0.6), lineWidth: 3)
                                        .padding(t.size * 0.22)
                                }
                                .position(t.pos)
                                .transition(.scale.combined(with: .opacity))
                                .onTapGesture {
                                    hits += 1
                                    spawn(in: geo.size)
                                }
                        }
                    }
                    .animation(.snappy(duration: 0.2), value: target)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding()
        .navigationTitle("Tap Rush")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(countdown) { _ in
            guard started, !finished else { return }
            timeLeft -= 1
            if timeLeft <= 0 {
                target = nil
                finished = true
            }
        }
    }

    private func spawn(in area: CGSize) {
        guard !finished else { return }
        let s = CGFloat.random(in: 52...92)
        let half = s / 2 + 6
        let t = Target(
            pos: CGPoint(x: .random(in: half...(max(half + 1, area.width - half))),
                         y: .random(in: half...(max(half + 1, area.height - half)))),
            size: s,
            color: [Theme.gold, Theme.accent, Theme.success, .purple, .pink].randomElement()!
        )
        target = t
        // Cible ratée si pas touchée à temps
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if target?.id == t.id, !finished, started {
                misses += 1
                spawn(in: area)
            }
        }
    }

    private func reset() {
        started = false
        finished = false
        timeLeft = duration
        hits = 0
        misses = 0
        target = nil
    }
}
