import Foundation
import Combine
import FirebaseFirestore

class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var recommendedProducts: [Product] = []
    
    let cat: Cat
    var healthIssues: [String]
    private let productService = ProductService()
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
        self.weightStatus = Self.calculateWeightStatus(cat: cat)
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
        var tags: Set<String> = []
        
        // 添加基础标签
        tags.insert(cat.breed.lowercased())
        
        // 基于年龄的推荐
        let age = Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0
        if age < 1 {
            tags.insert("kitten")
            newRecommendations.append(Recommendation(
                title: "Kitten Formula",
                description: "Special nutrition for growing kittens under 1 year",
                type: .food,
                priority: .high
            ))
        } else if age > 7 {
            tags.insert("senior")
            newRecommendations.append(Recommendation(
                title: "Senior Cat Food",
                description: "Enhanced nutrition for cats over 7 years",
                type: .food,
                priority: .high
            ))
        }
        
        // 基于体重状态的推荐
        switch weightStatus {
        case .underweight:
            tags.insert("high-calorie")
            newRecommendations.append(Recommendation(
                title: "High-Calorie Food",
                description: "Premium food with higher calorie content",
                type: .food,
                priority: .high
            ))
        case .overweight:
            tags.insert("weight-control")
            newRecommendations.append(Recommendation(
                title: "Weight Management Food",
                description: "Special formula for weight control",
                type: .food,
                priority: .high
            ))
        case .normal:
            tags.insert("maintenance")
            newRecommendations.append(Recommendation(
                title: "Maintenance Formula",
                description: "Balanced nutrition for adult cats",
                type: .food,
                priority: .medium
            ))
        }
        
        // 基于健康问题的推荐
        for issue in healthIssues {
            tags.insert(issue.lowercased())
            if let recommendation = getHealthRecommendation(for: issue) {
                newRecommendations.append(recommendation)
            }
        }
        
        print("Generated tags: \(tags)")  // 添加调试信息
        
        recommendations = newRecommendations
        
        // 从 Firebase 获取匹配的产品
        productService.fetchProducts(matching: Array(tags)) { [weak self] products in
            print("Fetched products: \(products.count)")  // 添加调试信息
            DispatchQueue.main.async {
                self?.recommendedProducts = products
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
} 