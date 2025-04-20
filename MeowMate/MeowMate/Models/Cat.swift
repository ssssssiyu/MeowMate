import UIKit

struct Cat: Codable {
    enum Gender: String, Codable {
        case male = "Male"
        case female = "Female"
    }
    
    let id: UUID
    let name: String
    let breed: String
    let birthDate: Date
    let gender: Gender
    var weight: Double
    var weightHistory: [WeightRecord]
    var isNeutered: Bool
    var image: UIImage?
    var imageURL: String?
    
    // 自定义初始化方法
    init(id: UUID = UUID(), name: String, breed: String, birthDate: Date, gender: Gender, weight: Double, weightHistory: [WeightRecord], isNeutered: Bool, image: UIImage? = nil, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.breed = breed
        self.birthDate = birthDate
        self.gender = gender
        self.weight = weight
        self.weightHistory = weightHistory
        self.isNeutered = isNeutered
        self.image = image
        self.imageURL = imageURL
    }
    
    // 计算属性：获取当前体重
    var currentWeight: Double {
        weightHistory.last?.weight ?? weight
    }
    
    // 计算属性：获取体重变化趋势
    var weightTrend: Double {
        guard weightHistory.count >= 2 else { return 0 }
        let sortedHistory = weightHistory.sorted { $0.date < $1.date }
        let lastWeight = sortedHistory.last?.weight ?? 0
        let previousWeight = sortedHistory[sortedHistory.count - 2].weight
        return lastWeight - previousWeight
    }
    
    // 计算属性：获取体重状态
    var weightStatus: WeightStatus {
        let idealWeight = getIdealWeight(breed: breed)
        let ratio = currentWeight / idealWeight
        
        if ratio < 0.9 {
            return .underweight
        } else if ratio > 1.1 {
            return .overweight
        } else {
            return .normal
        }
    }
    
    private func getIdealWeight(breed: String) -> Double {
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
    
    // 添加编码键
    enum CodingKeys: String, CodingKey {
        case id, name, breed, birthDate, gender, weight, weightHistory, isNeutered, imageURL, imageData
    }
    
    // 实现编码方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(breed, forKey: .breed)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(gender, forKey: .gender)
        try container.encode(weight, forKey: .weight)
        try container.encode(weightHistory, forKey: .weightHistory)
        try container.encode(isNeutered, forKey: .isNeutered)
        try container.encode(imageURL, forKey: .imageURL)
        
        // 编码图片数据
        if let image = image {
            let imageData = image.jpegData(compressionQuality: 0.8)
            try container.encode(imageData, forKey: .imageData)
        }
    }
    
    // 实现解码方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        breed = try container.decode(String.self, forKey: .breed)
        birthDate = try container.decode(Date.self, forKey: .birthDate)
        gender = try container.decode(Gender.self, forKey: .gender)
        weight = try container.decode(Double.self, forKey: .weight)
        weightHistory = try container.decode([WeightRecord].self, forKey: .weightHistory)
        isNeutered = try container.decode(Bool.self, forKey: .isNeutered)
        imageURL = try container.decodeIfPresent(String?.self, forKey: .imageURL) ?? nil
        
        // 解码图片数据
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            image = UIImage(data: imageData)
        } else {
            image = nil
        }
    }
}

enum WeightStatus {
    case underweight
    case normal
    case overweight
}

// WeightRecord 也需要支持 Codable
struct WeightRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var weight: Double
}


