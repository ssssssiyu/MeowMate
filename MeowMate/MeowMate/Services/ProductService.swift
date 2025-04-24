import Foundation
import FirebaseFirestore

class ProductService {
    // 使用 FirebaseConfig 中的 db 实例
    private let db = FirebaseConfig.db
    
    // 添加测试方法
    func testFirebaseConnection() {
        let testCollection = db.collection("petsmart_products")
        testCollection.getDocuments { (snapshot: QuerySnapshot?, error: Error?) in
            if error != nil {
                return
            }
            
            if snapshot != nil {
                // 连接成功
            }
        }
    }
    
    func fetchPetsmartProducts(lifeStage: String, healthConsiderations: [String]) async throws -> [PetFoodProduct] {
        let productsRef = db.collection(FirebaseConfig.Collections.products)
        
        let snapshot = try await productsRef.getDocuments()
        
        let products = snapshot.documents.compactMap { (document: QueryDocumentSnapshot) -> PetFoodProduct? in
            let data = document.data()
            
            let product = PetFoodProduct(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                link: data["link"] as? String ?? "",
                lifeStage: data["life_stage"] as? String ?? "All",
                brand: data["brand"] as? String,
                flavor: data["flavor"] as? String
            )
            
            return product
        }
        
        return products
    }
} 