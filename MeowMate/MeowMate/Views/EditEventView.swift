import SwiftUI
import UserNotifications  // 如果需要处理通知

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    let event: Event
    let onUpdate: (Event) -> Void
    let onDelete: (Event) -> Void  // 添加删除回调
    
    @State private var eventName: String
    @State private var eventDate: Date
    @State private var selectedReminders: Set<Event.ReminderType>
    @State private var showingDeleteAlert = false  // 添加删除确认
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(event: Event, onUpdate: @escaping (Event) -> Void, onDelete: @escaping (Event) -> Void) {
        self.event = event
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _eventName = State(initialValue: event.name)
        _eventDate = State(initialValue: event.date)
        _selectedReminders = State(initialValue: Set(event.reminderTypes))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Name", text: $eventName)
                    DatePicker("Date", selection: $eventDate, displayedComponents: [.date])
                        .tint(Theme.mintGreen)
                }
                
                Section(header: Text("Reminders")) {
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
                        .tint(Theme.mintGreen)
                    }
                }
                
                // 添加删除按钮
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Event")
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Text.navigationTitle("Edit Event")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.mintGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(eventName.isEmpty)
                    .foregroundColor(eventName.isEmpty ? .gray : Theme.mintGreen)
                }
            }
            .alert("Delete Event", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveEvent() {
        let updatedEvent = Event(
            id: event.id,
            name: eventName,
            date: eventDate,
            reminderTypes: Array(selectedReminders),
            catId: event.catId
        )
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                // 删除旧的提醒
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: event.reminderTypes.map { "\(event.id.uuidString)_\($0.rawValue)" }
                )
                
                // 添加新的提醒
                for reminderType in selectedReminders {
                    scheduleNotification(for: updatedEvent, reminderType: reminderType)
                }
                
                DispatchQueue.main.async {
                    onUpdate(updatedEvent)
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
} 
 
