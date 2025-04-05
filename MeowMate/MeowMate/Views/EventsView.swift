import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel: EventsViewModel
    @State private var showingAddEvent = false
    @State private var selectedEvent: Event?
    
    init(catId: String) {
        _viewModel = StateObject(wrappedValue: EventsViewModel(catId: catId))
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Events")
                            .font(.subheadline)
                            .bold()
                        
                        Spacer()
                        
                        Text("\(viewModel.events.count) upcoming")
                            .font(.subheadline)
                    }
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    if viewModel.events.isEmpty {
                        Text("No upcoming events")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.events.sorted { $0.date < $1.date }) { event in
                            EventRow(event: event, onEdit: {
                                selectedEvent = event
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteEvent(event)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .onTapGesture {
                    showingAddEvent = true
                }
                .sheet(isPresented: $showingAddEvent) {
                    AddEventView(catId: viewModel.catId, onSave: { event in
                        viewModel.addEvent(event)
                    })
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
    }
}

struct EventRow: View {
    let event: Event
    let onEdit: () -> Void
    
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
        .contentShape(Rectangle())  // 确保整个区域可点击
        .onTapGesture {
            onEdit()
        }
    }
} 