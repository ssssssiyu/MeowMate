import Foundation
import Combine
import FirebaseFirestore

class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var recommendedProducts: [PetFoodProduct] = [] {
        didSet {
            // Update UI if needed
        }
    }
    
    let cat: Cat
    var healthIssues: [String]
    private let productService: ProductService
    let weightStatus: WeightStatus
    
    enum WeightStatus {
        case underweight
        case normal
        case overweight
        
        var threshold: (min: Double, max: Double) {
            switch self {
            case .underweight: return (0, 0.9)
            case .normal: return (0.9, 1.1)
            case .overweight: return (1.1, Double.infinity)
            }
        }
    }
    
    init(cat: Cat, healthIssues: [String]) {
        self.cat = cat
        self.healthIssues = healthIssues
        self.productService = ProductService()
        self.weightStatus = Self.calculateWeightStatus(cat: cat)
        
        // 添加连接测试
        productService.testFirebaseConnection()
        
        generateRecommendations()
    }
    
    func updateHealthIssues(_ issues: [String]) {
        self.healthIssues = issues
        generateRecommendations()
    }
    
    struct Recommendation: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let type: RecommendationType
        let priority: Priority
        
        enum RecommendationType {
            case food
            case supplement
            case activity
            case medical
        }
        
        enum Priority {
            case high
            case medium
            case low
        }
    }
    
    private static func calculateWeightStatus(cat: Cat) -> WeightStatus {
        // 这里需要根据猫的品种和体重计算体重状态
        // 这是一个简化的示例
        let idealWeight = getIdealWeight(breed: cat.breed)
        let currentWeight = cat.weightHistory.last?.weight ?? cat.weight
        let ratio = currentWeight / idealWeight
        
        if ratio < 0.9 {
            return .underweight
        } else if ratio > 1.1 {
            return .overweight
        } else {
            return .normal
        }
    }
    
    private static func getIdealWeight(breed: String) -> Double {
        // 这里需要添加不同品种的理想体重范围
        // 这是一个简化的示例
        switch breed {
        case "Persian":
            return 4.0
        case "Siamese":
            return 3.5
        case "Maine Coon":
            return 6.0
        default:
            return 4.0
        }
    }
    
    private func generateRecommendations() {
        var newRecommendations: [Recommendation] = []
        
        // 1. 基于年龄的推荐
        let ageInMonths = Calendar.current.dateComponents([.month], from: cat.birthDate, to: Date()).month ?? 0
        let lifeStage: String
        if ageInMonths < 12 {
            lifeStage = "Kitten"
            newRecommendations.append(Recommendation(
                title: "Kitten Formula",
                description: "Special nutrition for growing kittens under 1 year",
                type: .food,
                priority: .high
            ))
        } else if ageInMonths > 84 {  // 7年 = 84个月
            lifeStage = "Senior"
            newRecommendations.append(Recommendation(
                title: "Senior Cat Food",
                description: "Enhanced nutrition for cats over 7 years",
                type: .food,
                priority: .high
            ))
        } else {
            lifeStage = "Adult"
            newRecommendations.append(Recommendation(
                title: "Adult Maintenance Formula",
                description: "Complete nutrition for adult cats",
                type: .food,
                priority: .medium
            ))
        }
        
        // 2. 基于体重状态的推荐
        switch weightStatus {
        case .underweight:
            newRecommendations.append(Recommendation(
                title: "Weight Gain Formula",
                description: "High-calorie diet for healthy weight gain",
                type: .food,
                priority: .high
            ))
        case .overweight:
            newRecommendations.append(Recommendation(
                title: "Weight Management Formula",
                description: "Low-calorie diet for healthy weight loss",
                type: .food,
                priority: .high
            ))
        case .normal:
            break
        }
        
        // 3. 基于健康问题的推荐
        for issue in healthIssues {
            if let recommendation = getHealthRecommendation(for: issue) {
                newRecommendations.append(recommendation)
            }
        }
        
        // 设置推荐
        self.recommendations = newRecommendations
        
        Task { @MainActor in
            do {
                let products = try await productService.fetchPetsmartProducts(
                    lifeStage: lifeStage,
                    healthConsiderations: []  // 不再使用健康考虑因素
                )
                
                // 确保在主线程更新并触发视图刷新
                await MainActor.run {
                    self.recommendedProducts = products
                    self.objectWillChange.send()
                }
            } catch {
                // Handle error if needed
            }
        }
    }
    
    private func getHealthRecommendation(for issue: String) -> Recommendation? {
        switch issue.lowercased() {
        case "hairball":
            return Recommendation(
                title: "Hairball Control Formula",
                description: "Special food with fiber to reduce hairballs",
                type: .food,
                priority: .medium
            )
        case "urinary":
            return Recommendation(
                title: "Urinary Health Formula",
                description: "Special diet for urinary tract health",
                type: .food,
                priority: .high
            )
        case "dental":
            return Recommendation(
                title: "Dental Care Formula",
                description: "Crunchy kibble for dental health",
                type: .food,
                priority: .medium
            )
        case "digestive issues":
            return Recommendation(
                title: "Digestive Care Formula",
                description: "Easy-to-digest food with prebiotics",
                type: .food,
                priority: .high
            )
        case "skin allergies":
            return Recommendation(
                title: "Sensitive Skin Formula",
                description: "Limited ingredient diet with omega fatty acids",
                type: .food,
                priority: .high
            )
        case "obesity":
            return Recommendation(
                title: "Weight Management Formula",
                description: "Low-calorie diet with high protein",
                type: .food,
                priority: .high
            )
        case "diabetes":
            return Recommendation(
                title: "Diabetic Care Formula",
                description: "Low carb diet with controlled protein",
                type: .food,
                priority: .high
            )
        case "kidney disease":
            return Recommendation(
                title: "Renal Support Formula",
                description: "Low phosphorus diet with controlled protein",
                type: .food,
                priority: .high
            )
        case "heart disease":
            return Recommendation(
                title: "Cardiac Health Formula",
                description: "Low sodium diet with taurine",
                type: .food,
                priority: .high
            )
        case "thyroid issues":
            return Recommendation(
                title: "Thyroid Support Formula",
                description: "Controlled iodine diet with antioxidants",
                type: .food,
                priority: .high
            )
        default:
            return nil
        }
    }
    
    func getProductsForRecommendation(_ recommendation: Recommendation) -> [PetFoodProduct] {
        // 根据推荐类型和标题过滤产品
        return recommendedProducts.filter { product in
            switch recommendation.type {
            case .food:
                // 根据推荐标题中的关键词匹配产品
                let keywords = recommendation.title.lowercased().components(separatedBy: " ")
                return keywords.contains { keyword in
                    product.name.lowercased().contains(keyword) ||
                    product.lifeStage.lowercased().contains(keyword)
                }
            default:
                return false
            }
        }
    }
}

// 重命名 Product 为 PetFoodProduct
struct PetFoodProduct: Identifiable {
    let id: String
    let name: String
    let link: String
    let lifeStage: String
    let brand: String?
    let flavor: String?
}

// 删除重复的 PetFoodProductService 类 