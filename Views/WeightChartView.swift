import SwiftUI
import Charts

struct WeightChartView: View {
    let records: [WeightRecord]
    let minWeight: Double
    let maxWeight: Double
    
    init(records: [WeightRecord] = []) {
        self.records = records
        self.minWeight = (records.map(\.weight).min() ?? 0) - 0.5
        self.maxWeight = (records.map(\.weight).max() ?? 0) + 0.5
    }
    
    var body: some View {
        VStack {
            Text("体重变化趋势")
                .font(.headline)
            
            if records.isEmpty {
                Text("暂无体重记录")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Chart {
                    ForEach(records) { record in
                        LineMark(
                            x: .value("日期", record.date),
                            y: .value("体重", record.weight)
                        )
                        
                        PointMark(
                            x: .value("日期", record.date),
                            y: .value("体重", record.weight)
                        )
                    }
                }
                .frame(height: 200)
                .padding()
                
                List(records) { record in
                    HStack {
                        Text("\(record.date, format: .dateTime.month().day())")
                        Spacer()
                        Text("\(record.weight, format: .number.precision(.fractionLength(1))) kg")
                    }
                }
                .frame(height: 150)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    WeightChartView(records: [
        WeightRecord(date: Date().addingTimeInterval(-7*24*3600), weight: 4.2),
        WeightRecord(date: Date().addingTimeInterval(-3*24*3600), weight: 4.5),
        WeightRecord(date: Date(), weight: 4.6)
    ])
} 