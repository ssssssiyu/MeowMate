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
            
            guard let productHealthConsideration = data["health_consideration"] as? String else {
                return nil
            }
            
            let productHealthArray = productHealthConsideration
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            let hasMatchingHealth = !healthConsiderations.isEmpty ? 
                healthConsiderations.contains { consideration in
                    productHealthArray.contains { $0.contains(consideration) }
                } : true
            
            if !hasMatchingHealth {
                return nil
            }
            
            return PetFoodProduct(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                price: data["price"] as? Double ?? 0.0,
                link: data["link"] as? String ?? "",
                foodType: data["food_type"] as? String ?? "",
                flavor: data["flavor"] as? String ?? "",
                healthConsideration: productHealthConsideration,
                nutritionalOption: data["nutritional_option"] as? String ?? "",
                breedSize: data["breed_size"] as? String ?? "",
                lifeStage: productLifeStage
            )
        }
        
        return filteredProducts
    }
} 