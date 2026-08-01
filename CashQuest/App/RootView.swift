import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var data: DataService
    @EnvironmentObject private var ads: AdManager

    var body: some View {
        Group {
            if let user = auth.user {
                MainTabView()
                    .task(id: user.uid) {
                        data.start(uid: user.uid)
                        ads.preload()
                    }
            } else {
                AuthView()
                    .onAppear { data.stop() }
            }
        }
        .animation(.smooth, value: auth.user?.uid)
    }
}
