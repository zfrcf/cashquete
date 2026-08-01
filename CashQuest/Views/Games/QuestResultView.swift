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

    var body: some View {
        VStack(spacing: 18) {
            Text("Score").font(.headline).foregroundStyle(.secondary)
            Text("\(score)")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gold)
                .transition(.scale.combined(with: .opacity))

            if let earned {
                Text("You earned \(earned) pts")
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
                Text(errorText)
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
        .task {
            do {
                earned = try await data.completeQuest(gameId: gameId, score: score)
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
