import SwiftUI
import Charts

struct WeightChartView: View {
    let records: [WeightRecord]
    
    @State private var timeRange: TimeRange = .oneMonth
    @State private var selectedRecord: WeightRecord?
    
    enum TimeRange: String, CaseIterable {
        case tenDays = "10 Days"
        case oneMonth = "1 Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        
        var days: Int {
            switch self {
            case .tenDays: return 10
            case .oneMonth: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            }
        }
    }
    
    var filteredRecords: [WeightRecord] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -timeRange.days,
            to: Date()
        ) ?? Date()
        
        return records
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }
    
    var yAxisRange: ClosedRange<Double> {
        let weights = filteredRecords.map(\.weight)
        let minWeight = max((weights.min() ?? 0) - 0.5, 0)  // 确保最小值不小于 0
        let maxWeight = (weights.max() ?? 0) + 0.5
        return minWeight...maxWeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Time range selector
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, -10)
            
            // Chart
            Chart {
                ForEach(filteredRecords) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.linear)
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(.blue)
                }
                
                if let selected = selectedRecord {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(.gray.opacity(0.3))
                        .annotation(position: .top) {
                            VStack(spacing: 4) {
                                Text(selected.date.formatted(date: .numeric, time: .omitted))
                                Text(String(format: "%.1f kg", selected.weight))
                                    .bold()
                            }
                            .padding(4)
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white)
                                    .shadow(radius: 1)
                            }
                        }
                }
            }
            .chartYScale(domain: yAxisRange)
            .chartYAxis {
                AxisMarks(values: .stride(by: (yAxisRange.upperBound - yAxisRange.lowerBound) / 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(weight, format: .number.precision(.fractionLength(1)))")
                                .padding(.trailing, 16)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = value.location.x - geometry[plotFrame].origin.x
                                    guard let date = proxy.value(atX: x, as: Date.self) else { return }
                                    
                                    selectedRecord = filteredRecords.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
                                }
                                .onEnded { _ in
                                    selectedRecord = nil
                                }
                        )
                }
            }
            .frame(height: 120)
            .padding(.top, 24)
            .padding(.leading, 8)
        }
    }
}
