import SwiftUI

enum Theme {
    static let mintGreen = Color(red: 55/255, green: 175/255, blue: 166/255)
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
    }
    
    enum Shadow {
        static let light: CGFloat = 2
        static let medium: CGFloat = 4
    }
    
    enum Text {
        static func navigationTitle(_ content: String) -> some View {
            SwiftUI.Text(content)
                .font(.custom("Chalkboard SE", size: 20))
                .foregroundColor(mintGreen)
        }
    }
} 