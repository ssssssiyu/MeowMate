import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var reminderTypes: [ReminderType]  // 保持数组，但可以为空
    let catId: String
    
    enum ReminderType: String, Codable, CaseIterable {
        case oneDay = "1 Day"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        case oneMonth = "1 Month"
        
        var timeInterval: TimeInterval {
            switch self {
            case .oneDay:
                return 86400 // 24 * 60 * 60
            case .threeDays:
                return 259200 // 3 * 24 * 60 * 60
            case .oneWeek:
                return 604800 // 7 * 24 * 60 * 60
            case .oneMonth:
                return 2592000 // 30 * 24 * 60 * 60
            }
        }
        
        // 保持自定义解码器来处理旧数据
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            
            switch rawValue {
                case "1 Day", "1 day before": self = .oneDay
                case "3 Days": self = .threeDays
                case "1 Week": self = .oneWeek
                case "1 Month": self = .oneMonth
                default:
                    print("⚠️ Converting old reminder type '\(rawValue)' to 'oneDay'")
                    self = .oneDay
            }
        }
    }
    
    // 添加一个便利初始化方法
    init(id: UUID = UUID(), name: String, date: Date, reminderTypes: [ReminderType] = [], catId: String) {
        self.id = id
        self.name = name
        self.date = date
        self.reminderTypes = reminderTypes
        self.catId = catId
    }
} 