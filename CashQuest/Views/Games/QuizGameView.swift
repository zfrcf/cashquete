import SwiftUI

/// Quiz de calcul contre la montre : 7 s par question, les séries rapportent un bonus.
struct QuizGameView: View {
    private struct Question {
        let text: String
        let answers: [Int]
        let correct: Int
    }

    private let questionTime = 7.0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var correctCount = 0
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var timeLeft = 7.0
    @State private var selected: Int?
    @State private var finished = false

    private var score: Int { correctCount * 8 + bestStreak * 4 }

    var body: some View {
        VStack(spacing: 18) {
            if finished {
                QuestResultView(gameId: "quiz", score: score, onReplay: start)
            } else if index < questions.count {
                let q = questions[index]

                HStack {
                    Text("Question \(index + 1)/10")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(streak)", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(streak > 0 ? Theme.gold : .secondary)
                        .contentTransition(.numericText())
                }

                timerBar

                Text(q.text)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Theme.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .contentTransition(.numericText())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(q.answers, id: \.self) { answer in
                        Button {
                            pick(answer, question: q)
                        } label: {
                            Text("\(answer)")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(buttonColor(answer, question: q))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(selected != nil)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Quiz Math")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if questions.isEmpty { start() } }
        .onReceive(timer) { _ in tick() }
        .animation(.snappy, value: index)
    }

    private var timerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.cardBackground)
                Capsule()
                    .fill(timeLeft > 2.5 ? Theme.success : Theme.danger)
                    .frame(width: max(0, geo.size.width * timeLeft / questionTime))
            }
        }
        .frame(height: 8)
    }

    private func tick() {
        guard !finished, !questions.isEmpty, selected == nil else { return }
        timeLeft -= 0.05
        if timeLeft <= 0 {
            selected = -1
            streak = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advance() }
        }
    }

    private func start() {
        finished = false
        index = 0
        correctCount = 0
        streak = 0
        bestStreak = 0
        selected = nil
        timeLeft = questionTime
        questions = (0..<10).map { _ in
            let a = Int.random(in: 3...15)
            let b = Int.random(in: 3...15)
            let correct = a * b
            var answers: Set<Int> = [correct]
            while answers.count < 4 {
                let delta = Int.random(in: -12...12)
                if delta != 0 { answers.insert(correct + delta) }
            }
            return Question(text: "\(a) × \(b) = ?", answers: answers.shuffled(), correct: correct)
        }
    }

    private func pick(_ answer: Int, question: Question) {
        guard selected == nil else { return }
        selected = answer
        if answer == question.correct {
            correctCount += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { advance() }
    }

    private func advance() {
        selected = nil
        timeLeft = questionTime
        if index + 1 < questions.count {
            index += 1
        } else {
            finished = true
        }
    }

    private func buttonColor(_ answer: Int, question: Question) -> Color {
        guard let selected else { return Theme.accent }
        if answer == question.correct { return Theme.success }
        if answer == selected { return Theme.danger }
        return Theme.accent.opacity(0.4)
    }
}
