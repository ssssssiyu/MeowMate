import Foundation

// 定义疾病类别
enum DiseaseCategory: String, Codable, CaseIterable {
    case digestive = "Digestive System"
    case urinary = "Urinary System"
    case respiratory = "Respiratory System"
    case skin = "Skin & Coat"
    case dental = "Dental Health"
    case metabolic = "Metabolic Disorders"
    case musculoskeletal = "Joints & Mobility"
    
    var systemImage: String {
        switch self {
        case .digestive: return "stomach"
        case .urinary: return "drop"
        case .respiratory: return "lungs"
        case .skin: return "allergens"
        case .dental: return "mouth"
        case .metabolic: return "chart.line.uptrend.xyaxis"
        case .musculoskeletal: return "figure.walk"
        }
    }
}

// 扩展 Disease 结构体，添加类别
struct Disease: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let symptoms: [String]
    let category: DiseaseCategory
    let recommendation: DietaryRecommendation
    
    struct DietaryRecommendation: Codable {
        let title: String
        let description: String
        let priority: Priority
        
        enum Priority: String, Codable {
            case high = "high"
            case medium = "medium"
            case low = "low"
        }
    }
    
    init(id: UUID = UUID(), name: String, description: String, symptoms: [String] = [], category: DiseaseCategory, recommendation: DietaryRecommendation) {
        self.id = id
        self.name = name
        self.description = description
        self.symptoms = symptoms
        self.category = category
        self.recommendation = recommendation
    }
} 