import Foundation
import SwiftUI

struct HealthAnalysis: Identifiable, Codable {
    let id: UUID
    let date: Date
    let catId: UUID
    let symptoms: [String]
    let possibleConditions: [String]
    let recommendations: [String]
    let urgencyLevel: String
    let catInfo: CatSnapshot  // 记录分析时的猫咪状态
    
    struct CatSnapshot: Codable {
        let age: Int
        let weight: Double
        let breed: String
        let isNeutered: Bool
        
        enum CodingKeys: String, CodingKey {
            case age, weight, breed, isNeutered
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case catId
        case symptoms
        case possibleConditions
        case recommendations
        case urgencyLevel
        case catInfo
    }
    
    init(id: UUID, date: Date, catId: UUID, symptoms: [String], 
         possibleConditions: [String], recommendations: [String], 
         urgencyLevel: String, catInfo: CatSnapshot) {
        self.id = id
        self.date = date
        self.catId = catId
        self.symptoms = symptoms
        self.possibleConditions = possibleConditions
        self.recommendations = recommendations
        self.urgencyLevel = urgencyLevel
        self.catInfo = catInfo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        catId = try container.decode(UUID.self, forKey: .catId)
        symptoms = try container.decode([String].self, forKey: .symptoms)
        possibleConditions = try container.decode([String].self, forKey: .possibleConditions)
        recommendations = try container.decode([String].self, forKey: .recommendations)
        urgencyLevel = try container.decode(String.self, forKey: .urgencyLevel)
        catInfo = try container.decode(CatSnapshot.self, forKey: .catInfo)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(catId, forKey: .catId)
        try container.encode(symptoms, forKey: .symptoms)
        try container.encode(possibleConditions, forKey: .possibleConditions)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(urgencyLevel, forKey: .urgencyLevel)
        try container.encode(catInfo, forKey: .catInfo)
    }
} 