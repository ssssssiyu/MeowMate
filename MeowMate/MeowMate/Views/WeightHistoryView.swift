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
        VStack(spacing: 0) {
            // 标题部分
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(Theme.mintGreen)
                Text("Weight Records")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    showingAddWeight = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.mintGreen)
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 内容部分
            ZStack {
                if sortedRecords.isEmpty {
                    VStack(spacing: Theme.Spacing.medium) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.mintGreen.opacity(0.8))
                        Text("No weight records yet")
                            .foregroundColor(.gray)
                            .font(.system(.body, design: .rounded))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 1) {  // 将间距改得很小
                            ForEach(sortedRecords) { record in
                                WeightRecordRow(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRecord = record
                                    }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding()
                    }
                }
            }
        }
        .padding(.top, 16)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weight History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Theme.Text.navigationTitle("Weight History")
            }
        }
        .sheet(isPresented: $showingAddWeight) {
            EditWeightView(
                date: Date(),
                weight: sortedRecords.first?.weight ?? 0,
                existingRecords: cat.weightHistory,
                onSave: { date, weight in
                    addWeight(date: date, weight: weight)
                },
                isEditing: false
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Text.navigationTitle("Add Weight Record")
                }
            }
        }
        .sheet(item: $selectedRecord) { record in
            EditWeightView(
                date: record.date,
                weight: record.weight,
                existingRecords: cat.weightHistory.filter { $0.id != record.id },
                onSave: { date, weight in
                    updateRecord(record, date: date, weight: weight)
                },
                isEditing: true,
                onDelete: {
                    deleteWeight(record: record)
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
            weight: weight,
            weightHistory: updatedHistory,
            isNeutered: cat.isNeutered,
            image: cat.image,
            imageURL: cat.imageURL
        )
        
        self.cat = updatedCat
        onUpdate(updatedCat)
    }
    
    private func deleteWeight(record: WeightRecord) {
        cat.weightHistory.removeAll { $0.id == record.id }
        onUpdate(cat)
    }
}

struct WeightRecordRow: View {
    let record: WeightRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f kg", record.weight))
                .font(.system(.body, design: .rounded))
                .foregroundColor(Theme.mintGreen)
                .bold()
        }
        .padding()
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
} 
