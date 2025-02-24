import Foundation

struct Event: Identifiable, Codable {
    let id: UUID
    let name: String
    let date: Date
    let reminderTypes: Set<ReminderType>
    let catId: String
    
    enum ReminderType: String, Codable, CaseIterable {
        case oneDay = "1 Day Before"
        case oneWeek = "1 Week Before"
        case twoWeeks = "2 Weeks Before"
        case oneMonth = "1 Month Before"
        
        var timeInterval: TimeInterval {
            switch self {
            case .oneDay:
                return 86400 // 24 * 60 * 60
            case .oneWeek:
                return 604800 // 7 * 24 * 60 * 60
            case .twoWeeks:
                return 1209600 // 14 * 24 * 60 * 60
            case .oneMonth:
                return 2592000 // 30 * 24 * 60 * 60
            }
        }
    }
} 