import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?
    let authManager = AuthenticationManager.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // 初始化 API Keys
        initializeAPIKeys()
        
        // 启动匿名登录
        Task {
            await authManager.ensureAnonymousUser()
        }
        
        return true
    }
    
    private func initializeAPIKeys() {
        #if DEBUG
        // 开发环境：从环境变量获取
        if let catAPIKey = ProcessInfo.processInfo.environment["CAT_API_KEY"] {
            KeychainService.save(key: catAPIKey, forAccount: "cat_api_key")
        }
        
        if let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            KeychainService.save(key: openAIKey, forAccount: "openai_api_key")
        }
        #endif
        
        // 从 Keychain 获取密钥
        if let catAPIKey = KeychainService.retrieve(forAccount: "cat_api_key") {
            do {
                try Config.API.setCatAPIKey(catAPIKey)
            } catch {
                print("⚠️ Warning: Failed to set Cat API key")
            }
        }
        
        if let openAIKey = KeychainService.retrieve(forAccount: "openai_api_key") {
            do {
                try Config.API.setOpenAIKey(openAIKey)
            } catch {
                print("⚠️ Warning: Failed to set OpenAI API key")
            }
        }
        
        // 验证 API Keys
        do {
            try Config.API.validateKeys()
        } catch {
            print("❌ Error: API keys validation failed")
            // 在生产环境中，你可能想要显示一个用户友好的错误信息
            // 或者实现一个重试机制
        }
    }
}

// 认证管理器
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var hasError = false
    
    private init() {}
    
    func ensureAnonymousUser() async {
        do {
            // 先登出当前用户（如果有的话）
            try? Auth.auth().signOut()
            
            // 强制重新匿名登录
            try await Auth.auth().signInAnonymously()
            
            await MainActor.run {
                self.isAuthenticated = true
                self.error = nil
                self.hasError = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isAuthenticated = false
                self.hasError = true
            }
            // 如果登录失败，等待3秒后重试
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await ensureAnonymousUser()
        }
    }
    
    // 强制重新登录的方法
    func forceReLogin() async {
        await ensureAnonymousUser()
    }
} 
