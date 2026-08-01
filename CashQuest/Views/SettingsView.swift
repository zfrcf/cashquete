import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var data: DataService
    @AppStorage("appTheme") private var appTheme = "auto"
    @AppStorage("hapticsEnabled") private var haptics = true
    @State private var selectedLanguage = Locale.preferredLanguages.first?.prefix(2).description ?? "en"
    @State private var showRestartAlert = false
    @State private var showDeleteConfirm = false

    // FR et EN sont traduits ; les autres tomberont sur l'anglais
    // tant que leurs traductions ne sont pas ajoutées au String Catalog.
    private let languages: [(code: String, label: String)] = [
        ("en", "English"), ("fr", "Français"), ("es", "Español"),
        ("de", "Deutsch"), ("it", "Italiano"), ("pt", "Português"),
        ("nl", "Nederlands"), ("tr", "Türkçe"), ("ru", "Русский"),
        ("ar", "العربية"), ("hi", "हिन्दी"), ("ja", "日本語"),
        ("ko", "한국어"), ("zh-Hans", "中文"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    LabeledContent("Name", value: data.profile?.displayName ?? "—")
                    LabeledContent("Email", value: auth.user?.email ?? "—")
                    LabeledContent("Referral code", value: data.profile?.referralCode ?? "—")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appTheme) {
                        Text("Automatic").tag("auto")
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.code) { lang in
                            Text(lang.label).tag(lang.code)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        showRestartAlert = true
                    }
                }

                Section("Navigation") {
                    NavigationLink("Tab order") { TabOrderView() }
                }

                Section {
                    Toggle("Haptics", isOn: $haptics)
                }

                Section("Account") {
                    Button("Sign out") { auth.signOut() }
                    Button("Delete account", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Restart the app to apply the language.", isPresented: $showRestartAlert) {
                Button("OK", role: .cancel) {}
            }
            .confirmationDialog("Delete your account? This cannot be undone.",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete account", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
            }
        }
    }
}

struct TabOrderView: View {
    @AppStorage("tabOrder") private var tabOrder = AppTab.defaultOrder

    private var tabs: [AppTab] {
        let parsed = tabOrder.split(separator: ",").compactMap { AppTab(rawValue: String($0)) }
        return parsed.isEmpty ? AppTab.allCases : parsed
    }

    var body: some View {
        List {
            ForEach(tabs) { tab in
                Label(tab.title, systemImage: tab.icon)
            }
            .onMove { from, to in
                var arr = tabs
                arr.move(fromOffsets: from, toOffset: to)
                tabOrder = arr.map(\.rawValue).joined(separator: ",")
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Tab order")
    }
}
