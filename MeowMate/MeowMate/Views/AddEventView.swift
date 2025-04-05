import SwiftUI
import UserNotifications

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    let catId: String
    let onSave: (Event) -> Void
    
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var selectedReminders: Set<Event.ReminderType> = []
    @State private var showingReminderOptions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $eventName)
                    DatePicker("Date", selection: $eventDate, displayedComponents: [.date])
                }
                
                Section(header: Text("Reminders (Optional)")) {
                    ForEach(Event.ReminderType.allCases, id: \.self) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { selectedReminders.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedReminders.insert(type)
                                } else {
                                    selectedReminders.remove(type)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(eventName.isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveEvent() {
        let event = Event(
            id: UUID(),
            name: eventName,
            date: eventDate,
            reminderTypes: Array(selectedReminders),
            catId: catId
        )
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                for reminderType in selectedReminders {
                    scheduleNotification(for: event, reminderType: reminderType)
                }
                onSave(event)
                DispatchQueue.main.async {
                    dismiss()
                }
            } else {
                DispatchQueue.main.async {
                    showingAlert = true
                    alertMessage = "Please enable notifications in Settings to receive reminders"
                }
            }
        }
    }
    
    private func scheduleNotification(for event: Event, reminderType: Event.ReminderType) {
        let content = UNMutableNotificationContent()
        content.title = "Event Reminder"
        content.body = "\(event.name) is coming up on \(event.date.formatted(date: .long, time: .omitted))"
        content.sound = .default
        
        let reminderDate = event.date.addingTimeInterval(-reminderType.timeInterval)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(event.id.uuidString)_\(reminderType.rawValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    private func loadEvents() -> [Event] {
        if let data = UserDefaults.standard.data(forKey: "events_\(catId)"),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            return decoded
        }
        return []
    }
} 

