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
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedEvent = Event(
                            id: event.id,
                            name: eventName,
                            date: eventDate,
                            reminderTypes: Array(selectedReminders),
                            catId: event.catId
                        )
                        onUpdate(updatedEvent)
                        dismiss()
                    }
                    .disabled(eventName.isEmpty)
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
        }
    }
} 