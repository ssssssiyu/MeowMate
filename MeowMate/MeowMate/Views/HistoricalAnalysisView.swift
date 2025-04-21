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
                            .foregroundColor(Theme.mintGreen)
                        ForEach(analysis.symptoms, id: \.self) { symptom in
                            Text("• \(symptom)")
                                .font(.body)
                        }
                    }
                    
                    // 可能的病因
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Possible Conditions")
                            .font(.headline)
                            .foregroundColor(Theme.mintGreen)
                        ForEach(analysis.possibleConditions, id: \.self) { condition in
                            Text("• \(condition)")
                                .font(.body)
                        }
                    }
                    
                    // 建议
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Advice")
                            .font(.headline)
                            .foregroundColor(Theme.mintGreen)
                        ForEach(analysis.recommendations, id: \.self) { recommendation in
                            Text("• \(recommendation)")
                                .font(.body)
                        }
                    }
                    
                    // 紧急程度
                    HStack {
                        Text("Care Level:")
                            .font(.headline)
                            .foregroundColor(Theme.mintGreen)
                        Text(analysis.urgencyLevel)
                            .font(.headline)
                            .foregroundColor(urgencyColor(analysis.urgencyLevel))
                    }
                }
                .padding()
            }
            .navigationTitle("Analysis History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Text.navigationTitle("Analysis History")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.mintGreen)
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