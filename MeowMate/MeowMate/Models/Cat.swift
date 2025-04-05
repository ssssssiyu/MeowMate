import UIKit

struct Cat: Identifiable, Codable {
    let id: UUID
    var name: String
    var breed: String
    var birthDate: Date
    var gender: Gender
    var weightHistory: [WeightRecord]
    var isNeutered: Bool
    var image: UIImage?
    var imageURL: String?
    
    enum Gender: String, Codable {
        case male = "Male"
        case female = "Female"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, breed, birthDate, gender, weightHistory, isNeutered, imageURL
    }
    
    var weight: Double {
        weightHistory.sorted { $0.date > $1.date }.first?.weight ?? 0
    }
    
    // 添加编码方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(breed, forKey: .breed)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(gender, forKey: .gender)
        try container.encode(weightHistory, forKey: .weightHistory)
        try container.encode(isNeutered, forKey: .isNeutered)
        try container.encode(imageURL, forKey: .imageURL)
        // image 不编码
    }
}

// WeightRecord 也需要支持 Codable
struct WeightRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var weight: Double
} 