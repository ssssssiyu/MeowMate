import SwiftUI

// 首先定义一个统一的颜色
let mintGreen = Color(red: 55/255, green: 175/255, blue: 166/255)

struct CatDetailView: View {
    @State private var displayedCat: Cat
    let cat: Cat
    let onDelete: () -> Void
    let onUpdate: (Cat) -> Void
    
    @StateObject private var wellnessViewModel: WellnessViewModel
    @StateObject private var recommendationViewModel: RecommendationViewModel
    @State private var selectedDiseases: [String] = []
    @State private var healthTips: [String] = []
    @State private var isWeightSectionExpanded: Bool = false
    @State private var isEditingProfile = false
    @State private var isPresentingCatInfoForm = false
    @StateObject private var eventsViewModel: EventsViewModel
    
    init(cat: Cat, onDelete: @escaping () -> Void, onUpdate: @escaping (Cat) -> Void) {
        self.cat = cat
        self._displayedCat = State(initialValue: cat)
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _wellnessViewModel = StateObject(wrappedValue: WellnessViewModel(cat: cat))
        _recommendationViewModel = StateObject(wrappedValue: RecommendationViewModel(cat: cat, healthIssues: []))
        _eventsViewModel = StateObject(wrappedValue: EventsViewModel(catId: cat.id.uuidString))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Section
                Section {
                    TabView {
                        // First Page - Basic Information
                        Button(action: {
                            isPresentingCatInfoForm = true
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "pawprint.circle.fill")
                                        .foregroundColor(mintGreen)
                                    Text("Basic Information")
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    Text(displayedCat.name)
                                        .font(.subheadline)
                                }
                                .padding(.bottom, 4)
                                
                                Divider()
                                
                                HStack(alignment: .top, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(displayedCat.breed)
                                            .font(.subheadline)
                                        let ageComponents = Calendar.current.dateComponents([.year, .month], from: displayedCat.birthDate, to: Date())
                                        Text(ageComponents.year ?? 0 >= 1 ? "\(ageComponents.year ?? 0) years" : "\(ageComponents.month ?? 0) months")
                                            .font(.subheadline)
                                        Text(displayedCat.gender.rawValue)
                                            .font(.subheadline)
                                        Text(displayedCat.isNeutered ? "Neutered" : "Not Neutered")
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    // Right side - Photo
                                    if let image = displayedCat.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                            .padding(.top, 8)
                                    } else if let imageURL = displayedCat.imageURL {
                                        // 使用已保存的 URL
                                        AsyncImage(url: URL(string: imageURL)) { phase in
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
                                                EmptyView()
                                            }
                                        }
                                    } else {
                                        // 显示占位图
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
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Second Page - Characteristics
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(mintGreen)
                                Text("Characteristics")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            BreedCharacteristicsView(breed: displayedCat.breed)
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Third Page - Description
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "photo.circle.fill")
                                    .foregroundColor(mintGreen)
                                Text("Description")
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding(.bottom, 4)
                            
                            Divider()
                            
                            BreedDescriptionView(breed: displayedCat.breed)
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
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(mintGreen)
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
                            
                            NavigationLink(destination: WeightHistoryView(cat: $displayedCat, onUpdate: { updatedCat in
                                displayedCat = updatedCat
                                onUpdate(updatedCat)
                            })) {
                                WeightChartView(records: displayedCat.weightHistory)
                                    .frame(height: 200)
                                    .padding(.horizontal, 20)
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
                    WellnessCard(cat: displayedCat)
                }
                .padding(.horizontal)
                
                // Recommendation Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundColor(mintGreen)
                            Text("Recommendations")
                                .font(.subheadline)
                                .bold()
                            
                            Spacer()
                            
                            NavigationLink(destination: ProductFilterView(
                                recommendation: recommendationViewModel.recommendations.first ?? RecommendationViewModel.Recommendation(
                                    title: "Pet Food",
                                    description: "",
                                    type: .food,
                                    priority: .medium
                                ),
                                products: recommendationViewModel.recommendedProducts
                            )) {
                                Text("Filter")
                                    .font(.subheadline)
                                    .foregroundColor(mintGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(
                                        Capsule()
                                            .stroke(mintGreen, lineWidth: 1)
                                    )
                            }
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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(mintGreen)
                            Text("Events")
                                .font(.subheadline)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(eventsViewModel.events.count) upcoming")
                                .font(.subheadline)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            eventsViewModel.showingAddEvent = true
                        }
                        .padding(.bottom, 4)
                        
                        Divider()
                        
                        EventsView(catId: displayedCat.id.uuidString, viewModel: eventsViewModel)
                            .padding(.vertical, 4)
                    }
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
        .navigationTitle(displayedCat.name)
        .onAppear {
            if let storedData = UserDefaults.standard.string(forKey: "selectedDiseases")?.data(using: .utf8),
               let diseases = try? JSONDecoder().decode([String].self, from: storedData) {
                wellnessViewModel.selectedDiseases = diseases
                wellnessViewModel.updateHealthTips()
                recommendationViewModel.updateHealthIssues(diseases)
            }
        }
        .sheet(isPresented: $isPresentingCatInfoForm) {
            CatInfoFormView(existingCat: displayedCat, onSave: { updatedCat, image in
                Task {
                    var finalCat = updatedCat
                    
                    // 如果用户选择了新图片
                    if let newImage = image {
                        finalCat.image = newImage
                        finalCat.imageURL = nil  // 清除旧的 URL，让系统重新上传
                    } 
                    // 如果品种改变了但没有新图片
                    else if updatedCat.breed != displayedCat.breed {
                        do {
                            if let breedImage = try await DataService.shared.fetchBreedImage(breed: updatedCat.breed) {
                                finalCat.imageURL = breedImage.url
                                finalCat.image = breedImage.image
                                print("✅ Successfully updated breed image")
                            } else {
                                print("⚠️ Could not get breed image, keeping existing image")
                                finalCat.image = displayedCat.image
                                finalCat.imageURL = displayedCat.imageURL
                            }
                        } catch {
                            print("❌ Error fetching breed image: \(error)")
                            finalCat.image = displayedCat.image
                            finalCat.imageURL = displayedCat.imageURL
                        }
                    }
                    // 如果什么都没改，保持原来的图片和 URL
                    else {
                        finalCat.image = displayedCat.image
                        finalCat.imageURL = displayedCat.imageURL
                    }
                    
                    displayedCat = finalCat
                    onUpdate(finalCat)
                }
            })
        }
    }
    
    // 添加获取当前体重的辅助函数
    private func getCurrentWeight() -> Double {
        let sortedRecords = displayedCat.weightHistory.sorted { $0.date > $1.date }
        return sortedRecords.first?.weight ?? 0  // 直接返回最新记录的体重，如果没有则返回0
    }
    
    // 将这些辅助类型和函数移到 struct 内部
    private struct BreedInfo: Codable {
        let reference_image_id: String?
    }

    private struct CatImage: Codable {
        let url: String
    }

    @MainActor
    private func updateCat(_ updatedCat: Cat, image: UIImage?) async {
        var finalCat = updatedCat
        
        if updatedCat.breed != displayedCat.breed {
            // 如果品种改变了，重新获取品种图片
            if let image = image {
                finalCat.image = image
            } else if let breedImage = try? await DataService.shared.fetchBreedImage(breed: updatedCat.breed) {
                finalCat.imageURL = breedImage.url
                finalCat.image = breedImage.image
            }
        } else {
            // 保持原有图片
            finalCat.image = image ?? displayedCat.image
            finalCat.imageURL = displayedCat.imageURL
        }
        
        displayedCat = finalCat
        onUpdate(finalCat)  // 这里会触发 HomeView 的更新
        isEditingProfile = false
    }
}

struct WellnessCard: View {
    let cat: Cat
    @StateObject private var viewModel: WellnessViewModel
    
    init(cat: Cat) {
        self.cat = cat
        _viewModel = StateObject(wrappedValue: WellnessViewModel(cat: cat))
    }
    
    var body: some View {
        NavigationLink(destination: WellnessView(cat: cat)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .foregroundColor(mintGreen)
                    Text("Wellness")
                        .font(.subheadline)
                        .bold()
                    
                    Spacer()
                    
                    if let urgencyLevel = viewModel.analysisHistory.first?.urgencyLevel {
                        Text(urgencyLevel)
                            .font(.subheadline)
                            .foregroundColor(urgencyColor(urgencyLevel))
                    } else {
                        Text("Healthy")
                            .font(.subheadline)
                            .foregroundColor(mintGreen)
                    }
                }
                .padding(.bottom, 4)
                
                Divider()
                
                if let recommendations = viewModel.analysisHistory.first?.recommendations,
                   !recommendations.isEmpty {
                    Text(recommendations.map { "• " + $0 }.joined(separator: "\n"))
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(6)
                        .truncationMode(.tail)
                } else {
                    Text("Tap to add health issues")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            do {
                let history = try await DataService.shared.fetchHealthAnalyses(forCat: cat.id)
                await MainActor.run {
                    viewModel.analysisHistory = history.sorted { $0.date > $1.date }
                    if viewModel.analysisHistory.count > 5 {
                        viewModel.analysisHistory = Array(viewModel.analysisHistory.prefix(5))
                    }
                }
            } catch {
                print("Error loading health analyses: \(error)")
            }
        }
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

