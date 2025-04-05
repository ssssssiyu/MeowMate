import SwiftUI

struct WeightHistoryView: View {
    @Binding var cat: Cat
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
                existingRecords: cat.weightHistory.filter { $0.id != record.id },
                onSave: { date, weight in
                    updateRecord(record, date: date, weight: weight)
                }
            )
        }
        .sheet(isPresented: $showingAddWeight) {
            EditWeightView(
                date: Date(),
                weight: 0,
                existingRecords: cat.weightHistory,
                onSave: { date, weight in
                    addWeight(date: date, weight: weight)
                }
            )
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addWeight(date: Date, weight: Double) {
        let newRecord = WeightRecord(id: UUID(), date: date, weight: weight)
        cat.weightHistory.append(newRecord)
        cat.weightHistory.sort { $0.date < $1.date }
        
        onUpdate(cat)
        
        Task {
            do {
                try await DataService.shared.saveCats([cat])
                print("✅ Weight record saved successfully")
            } catch {
                print("❌ Error saving weight record: \(error)")
            }
        }
    }
    
    private func updateRecord(_ record: WeightRecord, date: Date, weight: Double) {
        let updatedRecord = WeightRecord(id: record.id, date: date, weight: weight)
        var updatedHistory = cat.weightHistory
        if let index = updatedHistory.firstIndex(where: { $0.id == record.id }) {
            updatedHistory[index] = updatedRecord
        }
        
        let updatedCat = Cat(
            id: cat.id,
            name: cat.name,
            breed: cat.breed,
            birthDate: cat.birthDate,
            gender: cat.gender,
            weightHistory: updatedHistory,
            isNeutered: cat.isNeutered,
            image: cat.image,
            imageURL: cat.imageURL
        )
        
        self.cat = updatedCat
        onUpdate(updatedCat)
        
        Task {
            do {
                try await DataService.shared.saveCats([updatedCat])
                print("✅ Weight record updated successfully")
            } catch {
                print("❌ Error updating weight record: \(error)")
            }
        }
    }
    
    private func deleteWeight(at offsets: IndexSet) {
        cat.weightHistory.remove(atOffsets: offsets)
        
        onUpdate(cat)
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
