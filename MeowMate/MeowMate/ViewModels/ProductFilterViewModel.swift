import Foundation
import Combine

class ProductFilterViewModel: ObservableObject {
    let recommendation: RecommendationViewModel.Recommendation
    private let allProducts: [PetFoodProduct]
    
    @Published var selectedFilter: FilterType = .brand {
        didSet {
            updateFilterOptions()
        }
    }
    
    @Published var selectedOptions: Set<String> = [] {
        didSet {
            updateFilteredProducts()
        }
    }
    
    @Published var filterOptions: [String] = []
    @Published var filteredProducts: [PetFoodProduct] = []
    
    enum FilterType {
        case brand
        case flavor
        case lifeStage
    }
    
    init(recommendation: RecommendationViewModel.Recommendation, products: [PetFoodProduct]) {
        self.recommendation = recommendation
        self.allProducts = products
        updateFilterOptions()
        updateFilteredProducts()
    }
    
    func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }
    
    func resetFilters() {
        selectedOptions.removeAll()
        updateFilteredProducts()
    }
    
    private func updateFilterOptions() {
        switch selectedFilter {
        case .brand:
            filterOptions = Array(Set(allProducts.compactMap { $0.brand })).sorted()
        case .flavor:
            filterOptions = Array(Set(allProducts.compactMap { $0.flavor })).sorted()
        case .lifeStage:
            filterOptions = Array(Set(allProducts.map { $0.lifeStage })).sorted()
        }
    }
    
    private func updateFilteredProducts() {
        if selectedOptions.isEmpty {
            filteredProducts = allProducts
            return
        }
        
        filteredProducts = allProducts.filter { product in
            switch selectedFilter {
            case .brand:
                return product.brand.map { selectedOptions.contains($0) } ?? false
            case .flavor:
                return product.flavor.map { selectedOptions.contains($0) } ?? false
            case .lifeStage:
                return selectedOptions.contains(product.lifeStage)
            }
        }
    }
} 