import SwiftUI

class CatDetailViewModel: ObservableObject {
    @Published var cat: Cat
    @Published var selectedWeightPeriod: WeightPeriod = .tenDays
    
    enum WeightPeriod: String, CaseIterable {
        case tenDays = "10 Days"
        case month = "1 Month"
        case quarter = "3 Months"
        case halfYear = "6 Months"
    }
    
    init(cat: Cat) {
        self.cat = cat
    }
    
    func getFilteredWeightRecords() -> [WeightRecord] {
        let now = Date()
        let calendar = Calendar.current
        let filterDate: Date
        
        switch selectedWeightPeriod {
        case .tenDays:
            filterDate = calendar.date(byAdding: .day, value: -10, to: now) ?? now
        case .month:
            filterDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            filterDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .halfYear:
            filterDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        }
        
        return cat.weightHistory
            .filter { $0.date >= filterDate }
            .sorted { $0.date < $1.date }
    }
    
    func calculateAge() -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: cat.birthDate, to: Date())
        let age = ageComponents.year ?? 0
        return "\(age) years"
    }
    
    func hasWarnings() -> Bool {
        return false
    }
} 