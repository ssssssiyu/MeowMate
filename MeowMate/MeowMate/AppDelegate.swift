import UIKit
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase has been configured")
        
        // 测试 Firestore 连接
        let db = FirebaseConfig.db
        db.collection(FirebaseConfig.Collections.products).getDocuments { snapshot, error in
            if let error = error {
                print("❌ Firestore connection error: \(error.localizedDescription)")
            } else {
                print("✅ Successfully connected to Firestore")
                print("📊 Found \(snapshot?.documents.count ?? 0) products in database")
            }
        }
        
        // 测试 Storage 连接
        let storage = FirebaseConfig.storage
        print("📦 Storage bucket: \(storage.reference().bucket)")
        
        return true
    }
} 
