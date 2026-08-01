import SwiftUI

/// Quiz de calcul mental : neutre en langue, donc jouable dans le monde entier.
struct QuizGameView: View {
    private struct Question {
        let text: String
        let answers: [Int]
        let correct: Int
    }

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var correctCount = 0
    @State private var finished = false
    @State private var selected: Int?

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                QuestResultView(gameId: "quiz", score: correctCount * 10, onReplay: start)
            } else if index < questions.count {
                let q = questions[index]
                ProgressView(value: Double(index), total: Double(questions.count))
                    .tint(Theme.gold)
                Text(q.text)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
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
        .animation(.snappy, value: index)
    }

    private func start() {
        finished = false
        index = 0
        correctCount = 0
        selected = nil
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
        selected = answer
        if answer == question.correct { correctCount += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            selected = nil
            if index + 1 < questions.count {
                index += 1
            } else {
                finished = true
            }
        }
    }

    private func buttonColor(_ answer: Int, question: Question) -> Color {
        guard let selected else { return Theme.accent }
        if answer == question.correct { return Theme.success }
        if answer == selected { return Theme.danger }
        return Theme.accent.opacity(0.4)
    }
}
