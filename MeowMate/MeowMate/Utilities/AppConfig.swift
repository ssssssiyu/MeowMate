import SwiftUI

enum AppConfig {
    enum Constants {
        static let chartHeight: CGFloat = 180
        static let cornerRadius: CGFloat = 15
        static let sectionSpacing: CGFloat = 20
        static let chartFontSize: CGFloat = 8
    }
    
    enum Layout {
        static let photoSize: CGFloat = 120
        static let horizontalPadding: CGFloat = 15
    }
    
    enum Callbacks {
        typealias Update = (Cat) -> Void
        typealias Delete = () -> Void
    }
} 