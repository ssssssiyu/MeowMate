import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let price: Double
    let url: String
    let type: ProductType
    let tags: [String]  // 用于匹配推荐（如 "kitten", "senior", "weight-control" 等）
    
    enum ProductType: String, Codable {
        case food
        case supplement
        case treat
        case other
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         price: Double,
         url: String,
         type: ProductType,
         tags: [String]) {
        self.id = id
        self.name = name
        self.price = price
        self.url = url
        self.type = type
        self.tags = tags
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String,
              let price = data["price"] as? Double,
              let url = data["url"] as? String,
              let typeRaw = data["type"] as? String,
              let type = ProductType(rawValue: typeRaw),
              let tags = data["tags"] as? [String]
        else { return nil }
        
        self.id = document.documentID
        self.name = name
        self.price = price
        self.url = url
        self.type = type
        self.tags = tags
    }
} 