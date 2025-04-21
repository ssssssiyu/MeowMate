import SwiftUI

struct AIAnalysisSection: View {
    @ObservedObject var viewModel: WellnessViewModel
    
    var body: some View {
        Section {
            AIAnalysisButton(
                isEnabled: !viewModel.selectedSymptoms.isEmpty,
                action: { viewModel.requestAIAdvice() }
            )
            
            if !viewModel.analysisHistory.isEmpty {
                ForEach(viewModel.analysisHistory.prefix(5)) { analysis in
                    HistoryAnalysisButton(
                        analysis: analysis,
                        action: { viewModel.showHistoricalAnalysis(analysis) }
                    )
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
} 