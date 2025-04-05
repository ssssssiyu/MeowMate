import SwiftUI

struct AIAnalysisButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Get AI Health Analysis")
                }
                .frame(width: 300)
                .foregroundColor(.white)
                .padding()
                .background(isEnabled ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!isEnabled)
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
} 