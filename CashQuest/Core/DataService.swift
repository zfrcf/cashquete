import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
final class DataService: ObservableObject {
    @Published var profile: UserProfile?
    @Published var transactions: [PointsTransaction] = []
    @Published var withdrawals: [Withdrawal] = []
    @Published var config = AppConfig()

    private let db = Firestore.firestore()
    private lazy var functions = Functions.functions()
    private var listeners: [ListenerRegistration] = []

    // MARK: - Écoute temps réel (tableau de bord)

    func start(uid: String) {
        stop()
        let userRef = db.collection("users").document(uid)

        listeners.append(userRef.addSnapshotListener { [weak self] snap, _ in
            self?.profile = try? snap?.data(as: UserProfile.self)
        })

        listeners.append(userRef.collection("transactions")
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snap, _ in
                self?.transactions = snap?.documents.compactMap { try? $0.data(as: PointsTransaction.self) } ?? []
            })

        listeners.append(userRef.collection("withdrawals")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snap, _ in
                self?.withdrawals = snap?.documents.compactMap { try? $0.data(as: Withdrawal.self) } ?? []
            })

        listeners.append(db.collection("config").document("app")
            .addSnapshotListener { [weak self] snap, _ in
                if let cfg = try? snap?.data(as: AppConfig.self) { self?.config = cfg }
            })
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners = []
        profile = nil
        transactions = []
        withdrawals = []
    }

    // MARK: - Cloud Functions (toute la logique d'argent est côté serveur)

    func completeQuest(gameId: String, score: Int) async throws -> Int {
        try await run {
            let result = try await self.functions.httpsCallable("completeQuest")
                .call(["gameId": gameId, "score": score])
            return (result.data as? [String: Any])?["points"] as? Int ?? 0
        }
    }

    @discardableResult
    func claimRewardedAd() async throws -> Int {
        try await run {
            let result = try await self.functions.httpsCallable("claimRewardedAd").call([:])
            return (result.data as? [String: Any])?["points"] as? Int ?? 0
        }
    }

    func redeemReferral(code: String) async throws {
        try await run {
            _ = try await self.functions.httpsCallable("redeemReferral").call(["code": code])
        }
    }

    func requestWithdrawal(method: String, points: Int, recipient: String) async throws {
        try await run {
            _ = try await self.functions.httpsCallable("requestWithdrawal")
                .call(["method": method, "points": points, "recipient": recipient])
        }
    }

    /// Traduit les erreurs techniques Firebase en messages compréhensibles.
    private func run<T>(_ op: () async throws -> T) async throws -> T {
        do {
            return try await op()
        } catch {
            let ns = error as NSError
            var message = ns.localizedDescription
            if ns.domain == FunctionsErrorDomain {
                switch FunctionsErrorCode(rawValue: ns.code) {
                case .notFound?:
                    message = NSLocalizedString(
                        "Server not deployed yet — run firebase deploy (see guide).",
                        comment: "")
                case .unavailable?, .deadlineExceeded?, .internal?:
                    message = NSLocalizedString(
                        "Can't reach the server. Check your connection and try again.",
                        comment: "")
                default:
                    break
                }
            }
            throw NSError(domain: "CashQuest", code: ns.code,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
