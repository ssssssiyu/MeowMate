import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MeowMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // 设置导航栏的主题色
        let mintGreen = UIColor(red: 55/255, green: 175/255, blue: 166/255, alpha: 1.0)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 24, weight: .bold)]
        
        // 设置导航栏按钮的主题色
        UINavigationBar.appearance().tintColor = mintGreen
        
        // 设置导航栏的外观
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 确保所有导航栏按钮都使用主题色
        UIBarButtonItem.appearance().tintColor = mintGreen
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
} 