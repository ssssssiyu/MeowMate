import Foundation
import Combine
import UserNotifications
import FirebaseFirestore

class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false  // 添加加载状态
    let catId: String
    private var listener: ListenerRegistration?
    
    init(catId: String) {
        self.catId = catId
        setupListener(catId: catId)
        Task {
            await loadEvents()
        }
    }
    
    private func setupListener(catId: String) {
        listener = DataService.shared.observeEvents(forCat: catId) { [weak self] events in
            // 在主线程更新 UI
            DispatchQueue.main.async {
                self?.events = events
            }
        }
    }
    
    deinit {
        // 清理监听器
        listener?.remove()
    }
    
    func loadEvents() async {
        isLoading = true
        do {
            let loadedEvents = try await DataService.shared.loadEvents(forCat: catId)
            
            // 过滤掉过期的事件
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let filteredEvents = loadedEvents.filter { event in
                let eventDate = calendar.startOfDay(for: event.date)
                return eventDate >= startOfToday
            }
            
            // 在主线程更新 UI
            await MainActor.run {
                self.events = filteredEvents
            }
        } catch {
            print("❌ Error loading events: \(error)")
        }
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func addEvent(_ event: Event) {
        Task {
            do {
                try await DataService.shared.saveEvent(event, forCat: catId)
                await loadEvents()  // 重新加载以更新列表
                print("✅ Event added successfully")
            } catch {
                print("❌ Error adding event: \(error)")
            }
        }
    }
    
    func deleteEvent(_ event: Event) {
        print("🗑 Starting to delete event: \(event.id)")
        Task {
            do {
                try await DataService.shared.deleteEvent(event, forCat: catId)
                // 取消通知
                for reminderType in event.reminderTypes {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(
                        withIdentifiers: ["\(event.id.uuidString)_\(reminderType.rawValue)"]
                    )
                }
                // 在主线程重新加载
                await loadEvents()
                print("✅ Event deleted successfully")
            } catch {
                print("❌ Error deleting event: \(error.localizedDescription)")
                print("Error details: \(error)")
            }
        }
    }
    
    func saveEvent(_ event: Event) async {
        do {
            try await DataService.shared.saveEvent(event, forCat: catId)
            await loadEvents()  // 重新加载以确保同步
        } catch {
            print("❌ Error saving event: \(error)")
        }
    }
    
    func updateEvent(_ event: Event) {
        Task {
            do {
                try await DataService.shared.saveEvent(event, forCat: catId)
                await loadEvents()  // 重新加载以更新列表
                print("✅ Event updated successfully")
            } catch {
                print("❌ Error updating event: \(error)")
            }
        }
    }
} 