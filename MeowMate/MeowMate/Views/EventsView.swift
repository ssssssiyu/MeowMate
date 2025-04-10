import SwiftUI

struct EventsView: View {
    let catId: String
    @ObservedObject var viewModel: EventsViewModel
    @State private var showingAddEvent = false
    
    init(catId: String, viewModel: EventsViewModel) {
        self.catId = catId
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.events.isEmpty {
                Text("No upcoming events")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.events) { event in
                    EventRow(event: event)
                }
            }
        }
        .contentShape(Rectangle())  // 确保整个区域可点击
        .onTapGesture {
            showingAddEvent = true
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(catId: catId) { event in
                // 使用 addEvent 方法来保存新事件
                viewModel.addEvent(event)
            }
        }
        .onAppear {
            viewModel.fetchEvents()  // 视图出现时刷新
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