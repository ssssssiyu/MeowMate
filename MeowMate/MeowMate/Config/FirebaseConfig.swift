import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

struct FirebaseConfig {
    static let db = Firestore.firestore()
    static let storage = Storage.storage()
    
    // Collection 名称常量
    struct Collections {
        static let products = "petsmart_products"
        static let cats = "cats"
        static let events = "events"  // 确保这个名称正确
    }
    
    // Storage 路径常量
    struct StoragePaths {
        static let catImages = "cat_images"
    }
    
    // 获取或创建设备ID
    static var deviceID: String {
        if let existingID = UserDefaults.standard.string(forKey: "device_id") {
            return existingID
        }
        
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "device_id")
        return newID
    }
} 