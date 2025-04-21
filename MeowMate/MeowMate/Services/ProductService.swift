import Foundation
import FirebaseFirestore

class ProductService {
    // 使用 FirebaseConfig 中的 db 实例
    private let db = FirebaseConfig.db
    
    // 添加测试方法
    func testFirebaseConnection() {
        let testCollection = db.collection("petsmart_products")
        testCollection.getDocuments { (snapshot: QuerySnapshot?, _: Error?) in
            // Handle snapshot if needed
        }
    }
    
    func fetchPetsmartProducts(lifeStage: String, healthConsiderations: [String]) async throws -> [PetFoodProduct] {
        let productsRef = db.collection(FirebaseConfig.Collections.products)
        
        let snapshot = try await productsRef.getDocuments()
        
        let filteredProducts = snapshot.documents.compactMap { (document: QueryDocumentSnapshot) -> PetFoodProduct? in
            let data = document.data()
            
            guard let productLifeStage = data["life_stage"] as? String else {
                return nil
            }
            
            // 修改生命阶段匹配逻辑
            let lifeStageMatches = productLifeStage == "All" || productLifeStage == lifeStage || lifeStage == "All"
            if !lifeStageMatches {
                return nil
            }
            
            return PetFoodProduct(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                link: data["link"] as? String ?? "",
                lifeStage: productLifeStage,
                brand: data["brand"] as? String,
                flavor: data["flavor"] as? String
            )
        }
        
        return filteredProducts
    }
} 