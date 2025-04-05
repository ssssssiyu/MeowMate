import SwiftUI

struct HistoricalAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    let analysis: HealthAnalysis
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 症状部分
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Symptoms")
                            .font(.headline)
                        ForEach(analysis.symptoms, id: \.self) { symptom in
                            Text("• \(symptom)")
                        }
                    }
                    
                    // 可能的病因
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Possible Conditions")
                            .font(.headline)
                        ForEach(analysis.possibleConditions, id: \.self) { condition in
                            Text("• \(condition)")
                        }
                    }
                    
                    // 建议
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Advice")
                            .font(.headline)
                        ForEach(analysis.recommendations, id: \.self) { recommendation in
                            Text("• \(recommendation)")
                        }
                    }
                    
                    // 紧急程度
                    HStack {
                        Text("Care Level:")
                            .font(.headline)
                        Text(analysis.urgencyLevel)
                            .foregroundColor(urgencyColor(analysis.urgencyLevel))
                            .bold()
                    }
                    
                    // 猫咪当时的状态
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cat's Status")
                            .font(.headline)
                        Text("Age: \(analysis.catInfo.age) years")
                        Text("Weight: \(String(format: "%.1f", analysis.catInfo.weight)) kg")
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func urgencyColor(_ urgency: String) -> Color {
        switch urgency {
        case "Immediate Care": return .red
        case "Urgent Care": return .orange
        case "Monitor": return .yellow
        case "Home Care": return .green
        default: return .blue
        }
    }
} 