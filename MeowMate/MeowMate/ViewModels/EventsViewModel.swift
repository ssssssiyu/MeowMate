import Foundation
import Combine
import UserNotifications

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    let catId: String
    
    init(catId: String) {
        self.catId = catId
        loadEvents()
    }
    
    func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "events_\(catId)"),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            events = decoded.filter { event in
                let eventDate = calendar.startOfDay(for: event.date)
                return eventDate >= startOfToday
            }
        }
    }
    
    func addEvent(_ event: Event) {
        var currentEvents = loadAllEvents()
        currentEvents.append(event)
        if let encoded = try? JSONEncoder().encode(currentEvents) {
            UserDefaults.standard.set(encoded, forKey: "events_\(catId)")
        }
        loadEvents()
    }
    
    private func loadAllEvents() -> [Event] {
        if let data = UserDefaults.standard.data(forKey: "events_\(catId)"),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            return decoded
        }
        return []
    }
    
    func deleteEvent(_ event: Event) {
        var currentEvents = loadAllEvents()
        currentEvents.removeAll { $0.id == event.id }
        if let encoded = try? JSONEncoder().encode(currentEvents) {
            UserDefaults.standard.set(encoded, forKey: "events_\(catId)")
        }
        // 同时取消相关的通知
        for reminderType in event.reminderTypes {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["\(event.id.uuidString)_\(reminderType.rawValue)"]
            )
        }
        loadEvents()
    }
} 