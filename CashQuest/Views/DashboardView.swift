import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var data: DataService
    @EnvironmentObject private var ads: AdManager

    private var usd: Double {
        Double(data.profile?.points ?? 0) * data.config.pointValueUSD
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    statsRow
                    chartCard
                    rewardedCard
                    activityCard
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Dashboard")
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your balance").font(.subheadline).opacity(0.85)
            Text("\(data.profile?.points ?? 0) pts")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: data.profile?.points)
            Text(usd, format: .currency(code: "USD"))
                .font(.title3.bold())
                .foregroundStyle(Theme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.heroGradient)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard("Total earned", value: "\(data.profile?.totalEarnedPoints ?? 0)", icon: "chart.line.uptrend.xyaxis", color: Theme.success)
            statCard("Quests done", value: "\(data.profile?.questCount ?? 0)", icon: "flag.checkered", color: Theme.accent)
        }
    }

    private func statCard(_ title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private struct DayEarning: Identifiable {
        let id = UUID()
        let date: Date
        let points: Int
    }

    private var dailyEarnings: [DayEarning] {
        let cal = Calendar.current
        let days = (0..<7).compactMap {
            cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: .now))
        }.reversed()
        return days.map { day in
            let total = data.transactions
                .filter { $0.points > 0 && cal.isDate($0.createdAt ?? .distantPast, inSameDayAs: day) }
                .reduce(0) { $0 + $1.points }
            return DayEarning(date: day, points: total)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days").font(.headline)
            Chart(dailyEarnings) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Points", day.points)
                )
                .foregroundStyle(Theme.gold.gradient)
                .cornerRadius(5)
            }
            .frame(height: 140)
        }
        .cardStyle()
    }

    private var rewardedCard: some View {
        Button {
            ads.showRewarded {
                Task { try? await data.claimRewardedAd() }
            }
        } label: {
            HStack {
                Image(systemName: "play.tv.fill").font(.title2)
                Text("Watch an ad, earn a bonus").bold()
                Spacer()
                Text("+\(data.config.rewardedAdPoints)")
                    .bold()
                    .foregroundStyle(Theme.gold)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Theme.gold.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent activity").font(.headline)
            if data.transactions.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(data.transactions.prefix(10)) { tx in
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: tx.type))
                            .frame(width: 34, height: 34)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tx.label).font(.subheadline.bold())
                            if let date = tx.createdAt {
                                Text(date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(tx.points >= 0 ? "+\(tx.points)" : "\(tx.points)")
                            .font(.subheadline.bold())
                            .foregroundStyle(tx.points >= 0 ? Theme.success : Theme.danger)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func icon(for type: String) -> String {
        switch type {
        case "quest": "gamecontroller.fill"
        case "rewarded_ad": "play.tv.fill"
        case "referral": "person.2.fill"
        case "withdrawal": "banknote.fill"
        case "refund": "arrow.uturn.left"
        default: "circle.fill"
        }
    }
}
