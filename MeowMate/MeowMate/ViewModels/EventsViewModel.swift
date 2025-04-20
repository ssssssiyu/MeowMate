import Foundation
import Combine
import UserNotifications

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var showingAddEvent = false
    private let catId: String
    private let eventsKey = "events_"
    
    init(catId: String) {
        self.catId = catId
        loadEvents()
    }
    
    private func loadEvents() {
        isLoading = true
        let key = eventsKey + catId
        if let data = UserDefaults.standard.data(forKey: key),
           let loadedEvents = try? JSONDecoder().decode([Event].self, from: data) {
            // 过滤掉过期的事件
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let filteredEvents = loadedEvents.filter { event in
                let eventDate = calendar.startOfDay(for: event.date)
                return eventDate >= startOfToday
            }.sorted { $0.date < $1.date }
            
            DispatchQueue.main.async {
                self.events = filteredEvents
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func saveEvents() {
        let key = eventsKey + catId
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func addEvent(_ event: Event) {
        DispatchQueue.main.async {
            self.events.append(event)
            self.events.sort { $0.date < $1.date }
            self.saveEvents()
        }
    }
    
    func deleteEvent(_ event: Event) {
        DispatchQueue.main.async {
            self.events.removeAll { $0.id == event.id }
            // 取消通知
            for reminderType in event.reminderTypes {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["\(event.id.uuidString)_\(reminderType.rawValue)"]
                )
            }
            self.saveEvents()
        }
    }
    
    func updateEvent(_ event: Event) {
        DispatchQueue.main.async {
            if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                self.events[index] = event
                self.events.sort { $0.date < $1.date }
                self.saveEvents()
            }
        }
    }
} 