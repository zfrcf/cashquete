import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard, games, referral, withdraw, settings
    var id: String { rawValue }

    static let defaultOrder = AppTab.allCases.map(\.rawValue).joined(separator: ",")

    var icon: String {
        switch self {
        case .dashboard: "chart.pie.fill"
        case .games: "gamecontroller.fill"
        case .referral: "person.2.fill"
        case .withdraw: "banknote.fill"
        case .settings: "gearshape.fill"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .dashboard: "Dashboard"
        case .games: "Games"
        case .referral: "Referral"
        case .withdraw: "Withdraw"
        case .settings: "Settings"
        }
    }
}

struct MainTabView: View {
    @AppStorage("tabOrder") private var tabOrder = AppTab.defaultOrder
    @State private var selection: AppTab = .dashboard
    @EnvironmentObject private var ads: AdManager
    @EnvironmentObject private var data: DataService

    private var tabs: [AppTab] {
        let parsed = tabOrder.split(separator: ",").compactMap { AppTab(rawValue: String($0)) }
        return parsed.isEmpty ? AppTab.allCases : parsed
    }

    var body: some View {
        Group {
            switch selection {
            case .dashboard: DashboardView()
            case .games: GamesView()
            case .referral: ReferralView()
            case .withdraw: WithdrawView()
            case .settings: SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            CustomTabBar(tabs: tabs, selection: $selection)
        }
        .onAppear { ads.tapInterval = data.config.interstitialTapInterval }
        .onChange(of: data.config.interstitialTapInterval) { _, newValue in
            ads.tapInterval = newValue
        }
    }
}

struct CustomTabBar: View {
    let tabs: [AppTab]
    @Binding var selection: AppTab
    @Namespace private var ns
    @AppStorage("hapticsEnabled") private var haptics = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = tab }
                    if haptics {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == tab ? Theme.accent : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.accent.opacity(0.15))
                                .matchedGeometryEffect(id: "selectedTab", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}
