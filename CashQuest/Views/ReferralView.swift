import SwiftUI

struct ReferralView: View {
    @EnvironmentObject private var data: DataService
    @State private var code = ""
    @State private var message: String?
    @State private var isSuccess = false

    private var myCode: String { data.profile?.referralCode ?? "------" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.accent)
                        Text("Invite friends").font(.title2.bold())
                        Text("You earn \(data.config.referralReferrerPoints) pts, your friend earns \(data.config.referralInviteePoints) pts")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text(myCode)
                            .font(.system(size: 34, weight: .black, design: .monospaced))
                            .kerning(4)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 22)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        ShareLink(item: "🎮 CashQuest — joue et gagne des récompenses ! Utilise mon code \(myCode) : https://cashquest.app/invite/\(myCode)") {
                            Label("Share my link", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    if data.profile?.referredBy == nil {
                        VStack(spacing: 12) {
                            Text("Enter a friend's code").font(.headline)
                            TextField("CODE", text: $code)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .multilineTextAlignment(.center)
                                .font(.title3.monospaced().bold())
                                .padding(12)
                                .background(Theme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Button {
                                redeem()
                            } label: {
                                Text("Redeem").bold().frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(code.trimmingCharacters(in: .whitespaces).count < 4)

                            if let message {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundStyle(isSuccess ? Theme.success : Theme.danger)
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Referral")
        }
    }

    private func redeem() {
        Task {
            do {
                try await data.redeemReferral(code: code.trimmingCharacters(in: .whitespaces))
                isSuccess = true
                message = NSLocalizedString("Code applied! Points added.", comment: "")
            } catch {
                isSuccess = false
                message = error.localizedDescription
            }
        }
    }
}
