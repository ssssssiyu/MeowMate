import SwiftUI

struct CharacteristicRow: View {
    let title: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            HStack(spacing: 2) {
                ForEach(0..<5) { index in
                    Image(systemName: index < value ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(index < value ? .yellow : .gray)
                }
            }
        }
    }
} 