import Foundation
import Combine
import FirebaseFirestore

class RecommendationViewModel: ObservableObject {
    @Published var recommendedProducts: [PetFoodProduct] = []
    @Published var filteredProducts: [PetFoodProduct] = []
    @Published var displayedProducts: [PetFoodProduct] = []
    
    private let productService: ProductService
    
    init() {
        self.productService = ProductService()
        loadProducts()
    }
    
    private func loadProducts() {
        Task {
            do {
                let products = try await productService.fetchPetsmartProducts(
                    lifeStage: "All",
                    healthConsiderations: []
                )
                await MainActor.run {
                    self.recommendedProducts = products
                    self.filteredProducts = products
                    self.displayedProducts = products
                }
            } catch {
                print("Error loading products: \(error)")
            }
        }
    }
    
    func updateFilteredProducts(_ products: [PetFoodProduct]) {
        DispatchQueue.main.async {
            self.filteredProducts = products
            self.displayedProducts = products
            self.objectWillChange.send()
        }
    }
}

struct PetFoodProduct: Identifiable {
    let id: String
    let name: String
    let link: String
    let lifeStage: String
    let brand: String?
    let flavor: String?
} 