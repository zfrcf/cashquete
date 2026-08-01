import SwiftUI
import GoogleMobileAds

/// Gère l'interstitiel « toutes les N interactions » et les rewarded videos.
/// IDs de test Google — à remplacer par tes vrais blocs AdMob avant publication.
@MainActor
final class AdManager: NSObject, ObservableObject {
    private let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    @Published private(set) var tapCount = 0
    var tapInterval = 2

    private var interstitial: GADInterstitialAd?
    private var rewarded: GADRewardedAd?

    func preload() {
        Task {
            await loadInterstitial()
            await loadRewarded()
        }
    }

    /// À appeler sur chaque clic de bouton significatif :
    /// affiche un interstitiel tous les `tapInterval` clics.
    func registerTap() {
        tapCount += 1
        guard tapCount % max(1, tapInterval) == 0 else { return }
        showInterstitial()
    }

    func showInterstitial() {
        guard let vc = rootViewController, let ad = interstitial else {
            Task { await loadInterstitial() }
            return
        }
        ad.present(fromRootViewController: vc)
        interstitial = nil
        Task { await loadInterstitial() }
    }

    func showRewarded(onReward: @escaping () -> Void) {
        guard let vc = rootViewController, let ad = rewarded else {
            Task { await loadRewarded() }
            return
        }
        ad.present(fromRootViewController: vc) { onReward() }
        rewarded = nil
        Task { await loadRewarded() }
    }

    // MARK: - Private

    private func loadInterstitial() async {
        interstitial = try? await GADInterstitialAd.load(
            withAdUnitID: interstitialUnitID, request: GADRequest())
    }

    private func loadRewarded() async {
        rewarded = try? await GADRewardedAd.load(
            withAdUnitID: rewardedUnitID, request: GADRequest())
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
    }
}
