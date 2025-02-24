import SwiftUI

struct AddWeightView: View {
    let cat: Cat
    let onUpdate: (Cat) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var wholeNumber = 4
    @State private var decimal = 0
    
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
            .navigationTitle("Add Weight Record")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveWeight()
                }
            )
        }
    }
    
    private func saveWeight() {
        let weight = Double(wholeNumber) + Double(decimal) / 10.0
        var updatedCat = cat
        let newRecord = WeightRecord(
            id: UUID(),
            date: selectedDate,
            weight: weight
        )
        updatedCat.weightHistory.append(newRecord)
        updatedCat.weight = weight  // 更新当前体重
        onUpdate(updatedCat)
        dismiss()
    }
}

