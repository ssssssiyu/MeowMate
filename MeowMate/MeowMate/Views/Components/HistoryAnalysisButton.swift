import SwiftUI

struct HistoryAnalysisButton: View {
    let analysis: HealthAnalysis
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // 时间和紧急程度
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text(DateFormatter.mediumStyle.string(from: analysis.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(analysis.urgencyLevel)
                        .font(.caption.bold())
                        .foregroundColor(urgencyColor(analysis.urgencyLevel))
                }
                
                // 症状列表
                Text("Symptoms: " + analysis.symptoms.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
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