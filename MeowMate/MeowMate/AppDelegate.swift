import UIKit
import FirebaseCore
import FirebaseFirestore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // 初始化 API Keys
        initializeAPIKeys()
        
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
                try APIConfig.setCatAPIKey(catAPIKey)
            } catch {
                print("⚠️ Warning: Failed to set Cat API key")
            }
        }
        
        if let openAIKey = KeychainService.retrieve(forAccount: "openai_api_key") {
            do {
                try APIConfig.setOpenAIKey(openAIKey)
            } catch {
                print("⚠️ Warning: Failed to set OpenAI API key")
            }
        }
        
        // 验证 API Keys
        do {
            try APIConfig.validateAPIKeys()
        } catch {
            print("❌ Error: API keys validation failed")
            // 在生产环境中，你可能想要显示一个用户友好的错误信息
            // 或者实现一个重试机制
        }
    }
} 
