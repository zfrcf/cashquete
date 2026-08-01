import SwiftUI

struct WithdrawView: View {
    @EnvironmentObject private var data: DataService
    @State private var method = "paypal"
    @State private var recipient = ""
    @State private var points = 500.0
    @State private var statusMessage: String?
    @State private var isSuccess = false
    @State private var busy = false

    private var balance: Int { data.profile?.points ?? 0 }
    private var minPoints: Int { data.config.minWithdrawalPoints }

    private var cooldownEnd: Date? {
        guard let last = data.profile?.lastWithdrawalAt else { return nil }
        let end = last.addingTimeInterval(data.config.withdrawalCooldownHours * 3600)
        return end > .now ? end : nil
    }

    private var sliderUpper: Double {
        max(Double(minPoints) + 1, Double(balance))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Your balance").font(.headline)
                        Spacer()
                        Text("\(balance) pts").font(.headline).foregroundStyle(Theme.gold)
                    }
                    .cardStyle()

                    Picker("Method", selection: $method) {
                        Text("PayPal").tag("paypal")
                        Text("Reward Link").tag("tangocard")
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amount").font(.headline)
                        Slider(value: $points,
                               in: Double(minPoints)...sliderUpper,
                               step: 50)
                        HStack {
                            Text("\(Int(points)) pts").bold()
                            Spacer()
                            Text(Double(Int(points)) * data.config.pointValueUSD,
                                 format: .currency(code: "USD"))
                                .bold()
                                .foregroundStyle(Theme.gold)
                        }
                        Text("Minimum: \(minPoints) pts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()

                    TextField("Recipient email", text: $recipient)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let end = cooldownEnd {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                            Text("Next withdrawal in")
                            Text(end, style: .timer).monospacedDigit().bold()
                        }
                        .font(.subheadline)
                        .foregroundStyle(Theme.gold)
                    }

                    Button {
                        submit()
                    } label: {
                        Group {
                            if busy {
                                ProgressView()
                            } else {
                                Text("Request withdrawal").bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(busy || cooldownEnd != nil || recipient.isEmpty || balance < minPoints)

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(isSuccess ? Theme.success : Theme.danger)
                            .multilineTextAlignment(.center)
                    }

                    historySection
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Withdraw")
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History").font(.headline)
            if data.withdrawals.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(data.withdrawals) { w in
                    HStack(spacing: 12) {
                        Image(systemName: w.method == "paypal" ? "p.circle.fill" : "gift.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(w.amountUSD, format: .currency(code: "USD")).bold()
                            if let date = w.createdAt {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(w.status)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor(w.status).opacity(0.15))
                            .foregroundStyle(statusColor(w.status))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .cardStyle()
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "paid": Theme.success
        case "failed": Theme.danger
        default: Theme.gold
        }
    }

    private func submit() {
        Task {
            busy = true
            defer { busy = false }
            do {
                try await data.requestWithdrawal(
                    method: method,
                    points: Int(points),
                    recipient: recipient.trimmingCharacters(in: .whitespaces))
                isSuccess = true
                statusMessage = NSLocalizedString("Withdrawal sent! 🎉", comment: "")
            } catch {
                isSuccess = false
                statusMessage = error.localizedDescription
            }
        }
    }
}
