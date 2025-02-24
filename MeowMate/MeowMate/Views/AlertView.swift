import SwiftUI

struct AlertView: View {
    let title: String
    let message: String
    let primaryButton: Alert.Button
    let secondaryButton: Alert.Button?
    @Binding var isPresented: Bool
    
    var body: some View {
        EmptyView()
            .alert(isPresented: $isPresented) {
                if let secondaryButton = secondaryButton {
                    Alert(
                        title: Text(title),
                        message: Text(message),
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton
                    )
                } else {
                    Alert(
                        title: Text(title),
                        message: Text(message),
                        dismissButton: primaryButton
                    )
                }
            }
    }
} 