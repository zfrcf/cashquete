import SwiftUI

/// 2048 complet : glisse pour fusionner les tuiles, encaisse quand tu veux.
struct Game2048View: View {
    @State private var grid = [[Int]](repeating: [Int](repeating: 0, count: 4), count: 4)
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        VStack(spacing: 16) {
            if finished {
                QuestResultView(gameId: "2048", score: score / 20, onReplay: start)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score").font(.caption).foregroundStyle(.secondary)
                        Text("\(score)")
                            .font(.title.bold())
                            .foregroundStyle(Theme.gold)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    Button {
                        finished = true
                    } label: {
                        Label("Cash out", systemImage: "banknote.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.success)
                    .disabled(score == 0)
                }
                gridView
                Text("Swipe to merge the tiles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .navigationTitle("2048")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if grid.flatMap({ $0 }).allSatisfy({ $0 == 0 }) { start() } }
        .animation(.snappy(duration: 0.15), value: grid)
        .animation(.snappy, value: score)
    }

    private var gridView: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { r in
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { c in
                        tile(grid[r][c])
                    }
                }
            }
        }
        .padding(10)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { g in
                    let dx = g.translation.width
                    let dy = g.translation.height
                    if abs(dx) > abs(dy) {
                        move(dx > 0 ? .right : .left)
                    } else {
                        move(dy > 0 ? .down : .up)
                    }
                }
        )
    }

    private func tile(_ value: Int) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(tileColor(value))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if value > 0 {
                    Text("\(value)")
                        .font(.system(size: value < 100 ? 30 : (value < 1000 ? 24 : 19),
                                      weight: .heavy, design: .rounded))
                        .foregroundStyle(value <= 4 ? Color.primary : .white)
                        .minimumScaleFactor(0.5)
                        .transition(.scale)
                }
            }
    }

    private func tileColor(_ value: Int) -> Color {
        switch value {
        case 0: Theme.background
        case 2: Color.gray.opacity(0.25)
        case 4: Color.gray.opacity(0.4)
        case 8: Color.orange.opacity(0.75)
        case 16: Color.orange
        case 32: Theme.danger.opacity(0.8)
        case 64: Theme.danger
        case 128, 256: Theme.gold
        case 512, 1024: Theme.accent
        default: Color.purple
        }
    }

    // MARK: - Logique du jeu

    private enum Dir { case left, right, up, down }

    private func move(_ d: Dir) {
        var g = grid
        var gained = 0
        var changed = false

        func slide(_ row: [Int]) -> [Int] {
            var arr = row.filter { $0 != 0 }
            var i = 0
            while i < arr.count - 1 {
                if arr[i] == arr[i + 1] {
                    arr[i] *= 2
                    gained += arr[i]
                    arr.remove(at: i + 1)
                }
                i += 1
            }
            return arr + Array(repeating: 0, count: 4 - arr.count)
        }

        for i in 0..<4 {
            let line: [Int]
            switch d {
            case .left: line = g[i]
            case .right: line = g[i].reversed()
            case .up: line = (0..<4).map { g[$0][i] }
            case .down: line = (0..<4).map { g[3 - $0][i] }
            }
            let out = slide(line)
            for j in 0..<4 {
                let v = out[j]
                switch d {
                case .left: if g[i][j] != v { changed = true }; g[i][j] = v
                case .right: if g[i][3 - j] != v { changed = true }; g[i][3 - j] = v
                case .up: if g[j][i] != v { changed = true }; g[j][i] = v
                case .down: if g[3 - j][i] != v { changed = true }; g[3 - j][i] = v
                }
            }
        }

        guard changed else { return }
        score += gained
        grid = g
        spawnTile()
        if isGameOver() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { finished = true }
        }
    }

    private func spawnTile() {
        var empty: [(Int, Int)] = []
        for r in 0..<4 {
            for c in 0..<4 where grid[r][c] == 0 {
                empty.append((r, c))
            }
        }
        if let (r, c) = empty.randomElement() {
            grid[r][c] = Int.random(in: 0..<10) == 0 ? 4 : 2
        }
    }

    private func isGameOver() -> Bool {
        for r in 0..<4 {
            for c in 0..<4 {
                if grid[r][c] == 0 { return false }
                if c < 3 && grid[r][c] == grid[r][c + 1] { return false }
                if r < 3 && grid[r][c] == grid[r + 1][c] { return false }
            }
        }
        return true
    }

    private func start() {
        grid = [[Int]](repeating: [Int](repeating: 0, count: 4), count: 4)
        score = 0
        finished = false
        spawnTile()
        spawnTile()
    }
}
