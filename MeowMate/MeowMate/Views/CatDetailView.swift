import SwiftUI

struct CatDetailView: View {
    let cat: Cat
    let onDelete: () -> Void
    let onUpdate: (Cat) -> Void
    
    @StateObject private var wellnessViewModel: WellnessViewModel
    @StateObject private var recommendationViewModel: RecommendationViewModel
    @State private var selectedDiseases: [String] = []
    @State private var healthTips: [String] = []
    @State private var isWeightSectionExpanded: Bool = false
    
    init(cat: Cat, onDelete: @escaping () -> Void, onUpdate: @escaping (Cat) -> Void) {
        self.cat = cat
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _wellnessViewModel = StateObject(wrappedValue: WellnessViewModel(cat: cat))
        _recommendationViewModel = StateObject(wrappedValue: RecommendationViewModel(cat: cat, healthIssues: []))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Section
                Section {
                    TabView {
                        // First Page - Basic Information
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Basic Information")
                                    .font(.subheadline)
                                    .bold()
                                
                                Spacer()
                                
                                Text(cat.name)
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(cat.breed)
                                        .font(.subheadline)
                                    Text("\(Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0) years")
                                        .font(.subheadline)
                                    Text(cat.gender.rawValue)
                                        .font(.subheadline)
                                    Text(cat.isNeutered ? "Neutered" : "Not Neutered")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Right side - Photo
                                if let image = cat.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .padding(.top, 8)
                                } else {
                                    // 使用 API 获取的默认照片
                                    AsyncImage(url: URL(string: "https://api.thecatapi.com/v1/images/search?breed_ids=\(cat.breed.replacingOccurrences(of: " ", with: "_").lowercased())")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                                .padding(.top, 8)
                                        case .failure(_), .empty:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                                .foregroundColor(.gray)
                                                .padding(.top, 8)
                                        @unknown default:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                                .foregroundColor(.gray)
                                                .padding(.top, 8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Second Page - Characteristics
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Characteristics")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            BreedCharacteristicsView(breed: cat.breed)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Third Page - Description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Description")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            BreedDescriptionView(breed: cat.breed)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(height: 160)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
                
                // Weight Tracking Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        // Header with toggle
                        Button(action: {
                            withAnimation {
                                isWeightSectionExpanded.toggle()
                            }
                        }) {
                            HStack {
                                // Left side - Title
                                HStack {
                                    Text("Weight Tracking")
                                        .font(.subheadline)
                                        .bold()
                                }
                                
                                Spacer()
                                
                                // Right side - Current Weight
                                Text("\(String(format: "%.1f", getCurrentWeight())) kg")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.primary)
                        }
                        .padding(.bottom, 4)
                        
                        if isWeightSectionExpanded {
                            Divider()
                            
                            NavigationLink(destination: WeightHistoryView(cat: cat, onUpdate: onUpdate)) {
                                WeightChartView(records: cat.weightHistory)
                                    .frame(height: 200)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
                
                // Wellness Section
                Section {
                    NavigationLink(destination: WellnessView(cat: cat)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Wellness")
                                    .font(.subheadline)
                                    .bold()
                                
                                Spacer()
                                
                                Text(wellnessViewModel.selectedDiseases.isEmpty ? "Healthy" : "\(wellnessViewModel.selectedDiseases.count) issues")
                                    .font(.subheadline)
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            if !wellnessViewModel.healthTips.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(wellnessViewModel.healthTips, id: \.self) { tip in
                                        HStack(spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                            Text(tip)
                                                .font(.callout)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                Text("Long press to add health issues")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
                
                // Recommendation Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recommendation")
                                .font(.subheadline)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(recommendationViewModel.recommendations.count) tips")
                                .font(.subheadline)
                        }
                        .padding(.bottom, 4)
                        
                        Divider()
                        
                        RecommendationView(viewModel: recommendationViewModel)
                            .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
                
                // Events Section
                Section {
                    EventsView(catId: cat.id.uuidString)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(cat.name)
        .onAppear {
            if let storedData = UserDefaults.standard.string(forKey: "selectedDiseases")?.data(using: .utf8),
               let diseases = try? JSONDecoder().decode([String].self, from: storedData) {
                wellnessViewModel.selectedDiseases = diseases
                wellnessViewModel.updateHealthTips()
                recommendationViewModel.updateHealthIssues(diseases)
            }
        }
    }
    
    // 添加获取当前体重的辅助函数
    private func getCurrentWeight() -> Double {
        let sortedRecords = cat.weightHistory.sorted { $0.date > $1.date }
        let now = Date()
        
        // 找到最接近当前日期的记录
        if let mostRecentRecord = sortedRecords.first(where: { $0.date <= now }) {
            return mostRecentRecord.weight
        }
        
        // 如果没有找到合适的记录，返回最后记录的体重
        return cat.weight
    }
}

