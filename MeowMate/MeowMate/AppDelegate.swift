import UIKit
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // 测试 Firestore 连接
        let db = FirebaseConfig.db
        db.collection(FirebaseConfig.Collections.products).getDocuments { _, _ in
            // Handle completion if needed
        }
        
        return true
    }
} 
