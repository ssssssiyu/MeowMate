import SwiftUI

struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingRecords: [WeightRecord]
    let onSave: (Date, Double) -> Void
    let isEditing: Bool
    let onDelete: (() -> Void)?  // 添加删除回调
    
    @State private var selectedDate: Date
    @State private var wholeNumber: Int
    @State private var decimal: Int
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDeleteAlert = false  // 添加删除确认弹窗状态
    
    // 添加最大日期限制
    private var maxDate: Date {
        Date()  // 当前日期作为最大值
    }
    
    init(date: Date, weight: Double, existingRecords: [WeightRecord], onSave: @escaping (Date, Double) -> Void, isEditing: Bool = false, onDelete: (() -> Void)? = nil) {
        self.existingRecords = existingRecords
        self.onSave = onSave
        self.isEditing = isEditing
        self.onDelete = onDelete
        _selectedDate = State(initialValue: date)
        _wholeNumber = State(initialValue: Int(weight))
        _decimal = State(initialValue: Int((weight.truncatingRemainder(dividingBy: 1)) * 10))
        
        // 设置日期选择器的主题色
        UIDatePicker.appearance().tintColor = UIColor(Theme.mintGreen)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Date")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("Date")
                            .foregroundColor(.primary)
                        Spacer()
                        DatePicker("", selection: $selectedDate,
                                 in: ...maxDate,
                                 displayedComponents: .date)
                        .labelsHidden()
                        .tint(Theme.mintGreen)
                    }
                    .padding()
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
                
                // 删除按钮，只在编辑模式下显示
                if isEditing {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Record")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Text.navigationTitle(isEditing ? "Edit Weight" : "Add Weight")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.mintGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                    }
                    .foregroundColor(Theme.mintGreen)
                }
            }
            .alert("Invalid Input", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Delete Record", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let onDelete = onDelete {
                        onDelete()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this weight record? This action cannot be undone.")
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
        let existingSameDay = existingRecords.contains { record in
            calendar.isDate(record.date, inSameDayAs: selectedDate)
        }
        
        if existingSameDay {
            alertMessage = "A weight record for this date already exists"
            showingAlert = true
            return
        }
        
        let weight = Double(wholeNumber) + Double(decimal) / 10.0
        onSave(selectedDate, weight)
        dismiss()
    }
} 