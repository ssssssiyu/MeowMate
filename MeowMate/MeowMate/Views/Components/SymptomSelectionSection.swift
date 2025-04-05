import SwiftUI

struct SymptomSelectionSection: View {
    @ObservedObject var viewModel: WellnessViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // AI 分析按钮
            AIAnalysisButton(
                isEnabled: !viewModel.selectedSymptoms.isEmpty,
                action: { viewModel.requestAIAdvice() }
            )
            
            // 症状选择区域
            VStack(spacing: 8) {
                Text("Select Symptoms")
                    .font(.headline)
                
                FlowLayout(spacing: 8) {
                    ForEach(CommonSymptoms.allCases, id: \.self) { symptom in
                        SymptomBubble(
                            symptom: symptom.rawValue,
                            isSelected: viewModel.isSymptomSelected(symptom)
                        )
                    }
                }
                .padding()
            }
            
            // 历史记录
            if !viewModel.analysisHistory.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Analysis History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.analysisHistory.prefix(3)) { analysis in
                        HistoryAnalysisButton(
                            analysis: analysis,
                            action: { viewModel.showHistoricalAnalysis(analysis) }
                        )
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
} 
