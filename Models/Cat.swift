import UIKit

struct Cat {
    enum Gender: String {
        case male = "Male"
        case female = "Female"
    }
    
    let name: String
    let breed: String
    let birthDate: Date
    let gender: Gender
    var weight: Double
    var weightHistory: [WeightRecord]
    var image: UIImage?
} 