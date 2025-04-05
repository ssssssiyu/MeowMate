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
    
    // 添加最大日期限制
    private var maxDate: Date {
        Date()  // 当前日期作为最大值
    }
    
    init(date: Date, weight: Double, existingRecords: [WeightRecord], onSave: @escaping (Date, Double) -> Void) {
        self.existingRecords = existingRecords
        self.onSave = onSave
        _selectedDate = State(initialValue: date)
        _wholeNumber = State(initialValue: Int(weight))
        _decimal = State(initialValue: Int((weight.truncatingRemainder(dividingBy: 1)) * 10))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日期选择器部分
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    DatePicker("", selection: $selectedDate, 
                             in: ...maxDate,  // 添加日期范围限制
                             displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
                .padding()
                
                // 体重选择器部分
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weight (kg)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack(spacing: 0) {
                        Picker("", selection: $wholeNumber) {
                            ForEach(0...20, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        
                        Text(".")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        
                        Picker("", selection: $decimal) {
                            ForEach(0...9, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .padding()
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Weight Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                    }
                }
            }
            .alert("Invalid Input", isPresented: $showingAlert) {
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