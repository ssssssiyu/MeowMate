import UIKit

struct Cat: Identifiable, Codable {
    let id: UUID
    var name: String
    var breed: String
    var birthDate: Date
    var gender: Gender
    var weight: Double
    var weightHistory: [WeightRecord]
    var isNeutered: Bool
    var image: UIImage?
    
    enum Gender: String, Codable {
        case male = "Male"
        case female = "Female"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, breed, birthDate, gender, weight, weightHistory, isNeutered
        // 不包含 image，因为 UIImage 不能直接编码
    }
    
    var currentWeight: Double {
        weightHistory.sorted(by: { $0.date > $1.date }).first?.weight ?? weight
    }
}

// WeightRecord 也需要支持 Codable
struct WeightRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var weight: Double
} 