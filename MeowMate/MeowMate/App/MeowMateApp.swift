import SwiftUI
import FirebaseCore

@main
struct MeowMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 24, weight: .bold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
} 