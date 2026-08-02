import SwiftUI

/// Écran de fin de partie commun : envoie le score au serveur
/// (qui plafonne la récompense à 1 $) et affiche le gain.
struct QuestResultView: View {
    let gameId: String
    let score: Int
    let onReplay: () -> Void

    @EnvironmentObject private var data: DataService
    @EnvironmentObject private var ads: AdManager
    @State private var earned: Int?
    @State private var errorText: String?
    @State private var bonusClaimed = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: earned != nil ? "trophy.fill" : "hourglass")
                .font(.system(size: 64))
                .foregroundStyle(Theme.gold.gradient)
                .scaleEffect(appeared ? 1 : 0.3)
                .rotationEffect(.degrees(appeared ? 0 : -15))
                .shadow(color: Theme.gold.opacity(0.5), radius: 14)

            Text("Score").font(.headline).foregroundStyle(.secondary)
            Text("\(score)")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
                .contentTransition(.numericText())

            if let earned {
                Label("You earned \(earned) pts", systemImage: "plus.circle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.success)
                    .transition(.scale.combined(with: .opacity))

                if !bonusClaimed {
                    Button {
                        ads.showRewarded {
                            bonusClaimed = true
                            Task { try? await data.claimRewardedAd() }
                        }
                    } label: {
                        Label("Bonus: watch an ad", systemImage: "play.tv.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.gold)
                }
            } else if let errorText {
                Label(errorText, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
            } else {
                ProgressView()
            }

            Button {
                ads.registerTap()
                onReplay()
            } label: {
                Label("Play again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .animation(.spring(duration: 0.4), value: earned)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.5)) { appeared = true }
        }
        .task {
            do {
                earned = try await data.completeQuest(gameId: gameId, score: score)
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
