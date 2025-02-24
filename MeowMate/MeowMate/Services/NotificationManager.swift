import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func scheduleNotification(for cat: Cat) {
        let content = UNMutableNotificationContent()
        content.title = "Time to check \(cat.name)'s weight"
        content.body = "Regular weight tracking helps monitor your cat's health"
        content.sound = .default
        
        // 设置每周提醒
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // 每周日
        dateComponents.hour = 10    // 上午10点
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weightCheck-\(cat.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelNotifications(for cat: Cat) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weightCheck-\(cat.id)"])
    }
} 