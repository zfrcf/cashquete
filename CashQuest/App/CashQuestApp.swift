import SwiftUI
import FirebaseCore
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}

@main
struct CashQuestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthService()
    @StateObject private var data = DataService()
    @StateObject private var ads = AdManager()
    @AppStorage("appTheme") private var appTheme = "auto"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(data)
                .environmentObject(ads)
                .preferredColorScheme(appTheme == "auto" ? nil : (appTheme == "dark" ? .dark : .light))
                .tint(Theme.accent)
        }
    }
}
