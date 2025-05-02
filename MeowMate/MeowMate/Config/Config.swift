import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

enum Config {
    // Firebase 相关配置
    enum Firebase {
        static let db = Firestore.firestore()
        static let storage = Storage.storage()
        
        enum Collections {
            static let products = "petsmart_products"
            static let cats = "cats"
            static let events = "events"
            static let wellness = "wellness"
            static let healthAnalyses = "healthAnalyses"
        }
        
        enum StoragePaths {
            static let catImages = "cat_images"
        }
    }
    
    // API 相关配置
    enum API {
        private static let hasInitializedKey = "hasInitializedAPIKeys"
        
        // OpenAI 配置
        enum OpenAI {
            static let model = "gpt-3.5-turbo"
            static let temperature = 0.7
            static let endpoint = "https://api.openai.com/v1/chat/completions"
        }
        
        static var openAIKey: String {
            // 从 Keychain 获取
            if let key = KeychainService.retrieve(forAccount: "openai"),
               !key.isEmpty {
                return key
            }
            // 从环境变量获取（开发时）
            if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
               !envKey.isEmpty {
                return envKey
            }
            return ""
        }
        
        static var catAPIKey: String {
            // 从 Keychain 获取
            if let key = KeychainService.retrieve(forAccount: "catapi"),
               !key.isEmpty {
                return key
            }
            // 从环境变量获取（开发时）
            if let envKey = ProcessInfo.processInfo.environment["CAT_API_KEY"],
               !envKey.isEmpty {
                return envKey
            }
            return ""
        }
        
        static func setupKeysIfNeeded() throws {
            let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)
            guard !hasInitialized else { return }
            
            if openAIKey.isEmpty {
                try setOpenAIKey(DefaultKeys.openAIKey)
            }
            if catAPIKey.isEmpty {
                try setCatAPIKey(DefaultKeys.catAPIKey)
            }
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
        }
        
        static func setOpenAIKey(_ key: String) throws {
            guard !key.isEmpty else { throw ConfigError.invalidKey }
            KeychainService.save(key: key, forAccount: "openai")
        }
        
        static func setCatAPIKey(_ key: String) throws {
            guard !key.isEmpty else { throw ConfigError.invalidKey }
            KeychainService.save(key: key, forAccount: "catapi")
        }
        
        static func validateKeys() throws {
            guard !openAIKey.isEmpty else { throw ConfigError.keyNotFound }
            guard !catAPIKey.isEmpty else { throw ConfigError.keyNotFound }
        }
    }
    
    // 设备相关配置
    enum Device {
        static var deviceID: String {
            if let existingID = UserDefaults.standard.string(forKey: "device_id") {
                return existingID
            }
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "device_id")
            return newID
        }
    }
    
    enum ConfigError: Error {
        case invalidKey
        case keyNotFound
    }
} 