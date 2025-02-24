import SwiftUI

struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingRecords: [WeightRecord]
    let onSave: (Date, Double) -> Void
    
    @State private var selectedDate: Date
    @State private var wholeNumber: Int
    @State private var decimal: Int
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(date: Date, weight: Double, existingRecords: [WeightRecord], onSave: @escaping (Date, Double) -> Void) {
        self.existingRecords = existingRecords
        self.onSave = onSave
        _selectedDate = State(initialValue: date)
        _wholeNumber = State(initialValue: Int(weight))
        _decimal = State(initialValue: Int((weight.truncatingRemainder(dividingBy: 1)) * 10))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                
                Section(header: Text("Weight (kg)")) {
                    HStack {
                        Picker("Whole Number", selection: $wholeNumber) {
                            ForEach(0...30, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Text(".")
                            .font(.title2)
                        
                        Picker("Decimal", selection: $decimal) {
                            ForEach(0...9, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Weight Record")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveWeight()
                }
            )
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveWeight() {
        // 检查日期是否在未来
        if selectedDate > Date() {
            alertMessage = "Cannot add weight record for future dates"
            showingAlert = true
            return
        }
        
        // 检查是否已存在同一天的记录
        let calendar = Calendar.current
        if existingRecords.contains(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
            alertMessage = "A weight record already exists for this date"
            showingAlert = true
            return
        }
        
        let weight = Double(wholeNumber) + Double(decimal) / 10.0
        onSave(selectedDate, weight)
        dismiss()
    }
} 