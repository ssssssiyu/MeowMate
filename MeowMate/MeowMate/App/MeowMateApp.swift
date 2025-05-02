import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct MeowMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showError = false

    init() {
        setupAppearance()
        setupAPIKeys()
    }
    
    private func setupAppearance() {
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
    
    private func setupAPIKeys() {
        do {
            // 初始化 API keys
            try Config.API.setupKeysIfNeeded()
        } catch {
            // 在初始化时发生错误，记录错误但继续运行
            // App 后续会在需要时再次尝试初始化
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    SplashScreenView()
                } else {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Connecting...")
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                }
            }
            .alert("Connection Error", isPresented: $showError) {
                Button("Retry") {
                    Task {
                        await authManager.forceReLogin()
                    }
                }
            } message: {
                Text(authManager.error?.localizedDescription ?? "Unable to connect to the server. Please check your network connection and try again.")
            }
            .onChange(of: authManager.hasError) { _, hasError in
                showError = hasError
            }
            .task {
                // 在视图加载时强制重新登录
                await authManager.forceReLogin()
            }
        }
    }
} 