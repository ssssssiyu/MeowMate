import Foundation
import FirebaseFirestore

class ProductService {
    private let db = Firestore.firestore()
    
    func fetchProducts(matching tags: [String], completion: @escaping ([Product]) -> Void) {
        db.collection("products")
            .whereField("tags", arrayContainsAny: tags)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching products: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let products = documents.compactMap { document -> Product? in
                    let data = document.data()
                    
                    guard let name = data["name"] as? String,
                          let price = data["price"] as? Double,
                          let url = data["url"] as? String,
                          let typeRaw = data["type"] as? String,
                          let type = Product.ProductType(rawValue: typeRaw),
                          let tags = data["tags"] as? [String]
                    else { return nil }
                    
                    return Product(
                        id: document.documentID,
                        name: name,
                        price: price,
                        url: url,
                        type: type,
                        tags: tags
                    )
                }
                
                completion(products)
            }
    }
} 