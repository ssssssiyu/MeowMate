import SwiftUI

struct EventsView: View {
    let catId: String
    @ObservedObject var viewModel: EventsViewModel
    @State private var selectedEvent: Event?
    
    init(catId: String, viewModel: EventsViewModel) {
        self.catId = catId
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.events.isEmpty {
                Text("No upcoming events")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.events) { event in
                    EventRow(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEvent = event
                        }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddEvent) {
            AddEventView(catId: catId) { event in
                viewModel.addEvent(event)
            }
        }
        .sheet(item: $selectedEvent) { event in
            EditEventView(
                event: event,
                onUpdate: { updatedEvent in
                    viewModel.updateEvent(updatedEvent)
                },
                onDelete: { event in
                    viewModel.deleteEvent(event)
                }
            )
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.name)
                    .font(.callout)
                Text(event.date.formatted(date: .long, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !event.reminderTypes.isEmpty {
                Text("\(event.reminderTypes.count) reminders")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
} 
