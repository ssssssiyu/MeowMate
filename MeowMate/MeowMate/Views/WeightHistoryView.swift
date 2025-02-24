import SwiftUI

struct WeightHistoryView: View {
    let cat: Cat
    let onUpdate: (Cat) -> Void
    
    @State private var showingAddWeight = false
    @State private var selectedRecord: WeightRecord?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var sortedRecords: [WeightRecord] {
        cat.weightHistory.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            ForEach(sortedRecords) { record in
                WeightRecordRow(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecord = record
                    }
            }
            
            Button(action: {
                showingAddWeight = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Record")
                }
            }
        }
        .navigationTitle("Weight History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRecord) { record in
            EditWeightView(
                date: record.date,
                weight: record.weight,
                existingRecords: cat.weightHistory.filter { $0.date != record.date },
                onSave: { newDate, newWeight in
                    updateRecord(oldRecord: record, newDate: newDate, newWeight: newWeight)
                }
            )
        }
        .sheet(isPresented: $showingAddWeight) {
            EditWeightView(
                date: Date(),
                weight: cat.weight,
                existingRecords: cat.weightHistory,
                onSave: { date, weight in
                    addNewRecord(date: date, weight: weight)
                }
            )
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func updateRecord(oldRecord: WeightRecord, newDate: Date, newWeight: Double) {
        var updatedCat = cat
        if let index = updatedCat.weightHistory.firstIndex(where: { $0.date == oldRecord.date }) {
            updatedCat.weightHistory[index] = WeightRecord(
                id: oldRecord.id,
                date: newDate,
                weight: newWeight
            )
            if index == updatedCat.weightHistory.count - 1 {
                updatedCat.weight = newWeight
            }
            onUpdate(updatedCat)
        }
    }
    
    private func addNewRecord(date: Date, weight: Double) {
        var updatedCat = cat
        updatedCat.weightHistory.append(WeightRecord(id: UUID(), date: date, weight: weight))
        updatedCat.weight = weight
        onUpdate(updatedCat)
    }
}

struct WeightRecordRow: View {
    let record: WeightRecord
    
    var body: some View {
        HStack {
            Text(record.date.formatted(date: .abbreviated, time: .omitted))
            Spacer()
            Text(String(format: "%.1f kg", record.weight))
        }
    }
} 
