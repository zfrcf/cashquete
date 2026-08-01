import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var points: Int
    var totalEarnedPoints: Int
    var questCount: Int?
    var referralCode: String
    var referredBy: String?
    var lastWithdrawalAt: Date?
    var createdAt: Date?
}

struct PointsTransaction: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String // quest | rewarded_ad | referral | withdrawal | refund
    var points: Int
    var label: String
    var createdAt: Date?
}

struct Withdrawal: Codable, Identifiable {
    @DocumentID var id: String?
    var method: String // paypal | tangocard
    var points: Int
    var amountUSD: Double
    var recipient: String
    var status: String // processing | paid | failed
    var createdAt: Date?
}

struct AppConfig: Codable {
    var pointValueUSD = 0.01
    var minWithdrawalPoints = 500
    var withdrawalCooldownHours = 3.0
    var maxQuestRewardPoints = 100
    var rewardedAdPoints = 10
    var interstitialTapInterval = 2
    var referralInviteePoints = 500
    var referralReferrerPoints = 1000
    var gameCooldownMinutes = 15.0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pointValueUSD = try c.decodeIfPresent(Double.self, forKey: .pointValueUSD) ?? 0.01
        minWithdrawalPoints = try c.decodeIfPresent(Int.self, forKey: .minWithdrawalPoints) ?? 500
        withdrawalCooldownHours = try c.decodeIfPresent(Double.self, forKey: .withdrawalCooldownHours) ?? 3.0
        maxQuestRewardPoints = try c.decodeIfPresent(Int.self, forKey: .maxQuestRewardPoints) ?? 100
        rewardedAdPoints = try c.decodeIfPresent(Int.self, forKey: .rewardedAdPoints) ?? 10
        interstitialTapInterval = try c.decodeIfPresent(Int.self, forKey: .interstitialTapInterval) ?? 2
        referralInviteePoints = try c.decodeIfPresent(Int.self, forKey: .referralInviteePoints) ?? 500
        referralReferrerPoints = try c.decodeIfPresent(Int.self, forKey: .referralReferrerPoints) ?? 1000
        gameCooldownMinutes = try c.decodeIfPresent(Double.self, forKey: .gameCooldownMinutes) ?? 15.0
    }
}
