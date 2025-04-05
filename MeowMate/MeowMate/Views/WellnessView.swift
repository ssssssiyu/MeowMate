import SwiftUI

struct WellnessView: View {
    @StateObject private var viewModel: WellnessViewModel
    @AppStorage("selectedDiseases") private var selectedDiseasesStorage: String = "[]"
    @State private var selectedDiseasesList: [String] = []
    @State private var showingDetail: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var cat: Cat
    @State private var showingAIAdvice = false
    @State private var selectedDisease: Disease?
    @State private var selectedTab = 0
    @State private var showingResetAlert = false
    
    init(cat: Cat) {
        _viewModel = StateObject(wrappedValue: WellnessViewModel(cat: cat))
        _cat = State(initialValue: cat)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 第一页：AI 分析
            List {
                Section {
                    SymptomSelectionSection(viewModel: viewModel)
                }
                
                if !viewModel.healthTips.isEmpty {
                    Section(header: Text("Health Tips")) {
                        ForEach(viewModel.healthTips, id: \.self) { tip in
                            Text(tip)
                        }
                    }
                }
            }
            .tag(0)
            .navigationTitle("Health Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .scaleEffect(0.9)
                    }
                }
            }
            .alert("Reset Health Analysis", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        do {
                            try await DataService.shared.deleteAllHealthAnalyses(forCat: cat.id)
                            await MainActor.run {
                                viewModel.analysisHistory = []
                            }
                        } catch {
                            print("❌ Failed to reset health analyses:", error)
                            viewModel.error = error
                        }
                    }
                }
            } message: {
                Text("This will delete all health analysis history. This action cannot be undone.")
            }
            
            // 第二页：疾病类别
            List {
                ForEach(DiseaseCategory.allCases, id: \.self) { category in
                    if !diseasesInCategory(category).isEmpty {
                        Section(header: CategoryHeader(category: category)) {
                            ForEach(diseasesInCategory(category)) { disease in
                                DiseaseRow(disease: disease)
                                    .onTapGesture {
                                        selectedDisease = disease
                                    }
                            }
                        }
                    }
                }
            }
            .tag(1)
            .navigationTitle("Disease Library")
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Select Symptoms")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("Clear All Symptoms"),
                message: Text("Are you sure you want to clear all selected symptoms?"),
                primaryButton: .destructive(Text("Clear")) {
                    selectedDiseasesList.removeAll()
                    if let data = try? JSONEncoder().encode(selectedDiseasesList),
                       let string = String(data: data, encoding: .utf8) {
                        selectedDiseasesStorage = string
                        viewModel.selectedDiseases = selectedDiseasesList
                        viewModel.updateHealthTips()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $selectedDisease) { disease in
            DiseaseDetailView(disease: disease)
        }
        .sheet(isPresented: $viewModel.showingAIAdvice) {
            AIAdviceView(viewModel: viewModel, symptoms: viewModel.selectedSymptoms)
        }
        .sheet(isPresented: $viewModel.showingHistoricalAnalysis) {
            if let analysis = viewModel.selectedHistoricalAnalysis {
                HistoricalAnalysisView(analysis: analysis)
            }
        }
        .onAppear {
            if let diseases = try? JSONDecoder().decode([String].self, from: selectedDiseasesStorage.data(using: .utf8) ?? Data()) {
                selectedDiseasesList = diseases
                viewModel.selectedDiseases = diseases
                viewModel.updateHealthTips()
            }
            // 直接使用 ViewModel 的 diseases 属性
            viewModel.diseases = viewModel.diseaseService.commonDiseases
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK", role: .cancel) {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func saveWellnessData() {
        // 保存到 UserDefaults
        if let encodedData = try? JSONEncoder().encode(selectedDiseasesList) {
            UserDefaults.standard.set(String(data: encodedData, encoding: .utf8), forKey: "selectedDiseases")
        }
        
        // 同时需要保存到 Firebase
        Task {
            await DataService.shared.saveWellnessData(catId: cat.id, diseases: selectedDiseasesList)
        }
    }
    
    // 获取特定类别的疾病
    private func diseasesInCategory(_ category: DiseaseCategory) -> [Disease] {
        viewModel.diseases.filter { $0.category == category }
    }
}

// 类别标题视图
struct CategoryHeader: View {
    let category: DiseaseCategory
    
    var body: some View {
        HStack {
            Image(systemName: category.systemImage)
            Text(category.rawValue)
        }
    }
}

struct DiseaseRow: View {
    let disease: Disease
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(disease.name)
                .font(.headline)
            Text(disease.symptoms.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct DiseasePickerView: View {
    @Binding var selectedDiseases: [String]
    let viewModel: WellnessViewModel
    let onSave: ([String]) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDetail: Bool = false
    @State private var selectedDiseaseString: String = ""
    @State private var showingClearAlert: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if !selectedDiseases.isEmpty {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Clear All")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(viewModel.diseaseOptions.keys.sorted(), id: \.self) { disease in
                        HStack {
                            Text(disease)
                            Spacer()
                            if selectedDiseases.contains(disease) {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDiseases.contains(disease) {
                                selectedDiseases.removeAll { $0 == disease }
                            } else {
                                selectedDiseases.append(disease)
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            selectedDiseaseString = disease
                            showingDetail = true
                        }
                    }
                }
            }
            .navigationTitle("Select Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(selectedDiseases)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("Clear All Symptoms"),
                    message: Text("Are you sure you want to clear all selected symptoms?"),
                    primaryButton: .destructive(Text("Clear")) {
                        selectedDiseases.removeAll()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $showingDetail) {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(selectedDiseaseString)
                                .font(.system(size: 24, weight: .bold))
                                .padding(.top)
                            
                            if let description = viewModel.localDiseases[selectedDiseaseString] {
                                Text(description)
                                    .font(.system(size: 16))
                                    .lineSpacing(8)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showingDetail = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DiseaseDetailView: View {
    let disease: Disease
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(disease.name)
                        .font(.title)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        Text(disease.description)
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Symptoms")
                            .font(.headline)
                        Text(disease.symptoms.joined(separator: ", "))
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dietary Recommendation")
                            .font(.headline)
                        Text(disease.recommendation.title)
                            .font(.subheadline)
                            .bold()
                        Text(disease.recommendation.description)
                            .font(.body)
                        
                        HStack {
                            Text("Priority:")
                            Text(disease.recommendation.priority.rawValue.capitalized)
                                .foregroundColor(priorityColor(disease.recommendation.priority))
                                .bold()
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func priorityColor(_ priority: Disease.DietaryRecommendation.Priority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let viewModel: WellnessViewModel
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .contextMenu {
            if let description = viewModel.localDiseases[title] {
                Text(description)
            }
            Button("Select/Deselect") {
                action()
            }
        }
    }
}

let diseases = [
    "Hairball",
    "Urinary",
    "Dental",
    "Digestive Issues",
    "Skin Allergies",
    "Ear Infections",
    "Eye Problems",
    "Respiratory Issues",
    "Joint Problems",
    "Obesity",
    "Diabetes",
    "Heart Disease",
    "Kidney Disease",
    "Liver Disease",
    "Thyroid Issues"
]

struct AIAdviceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WellnessViewModel
    let symptoms: Set<CommonSymptoms>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let response = viewModel.aiResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Possible Causes")
                                .font(.headline)
                            ForEach(response.possibleConditions, id: \.self) { condition in
                                Text("• \(condition)")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Advice")
                                .font(.headline)
                            ForEach(response.recommendations, id: \.self) { recommendation in
                                Text("• \(recommendation)")
                            }
                        }
                        
                        HStack {
                            Text("Care Level:")
                                .font(.headline)
                            Text(response.urgencyLevel.rawValue)
                                .foregroundColor(urgencyColor(response.urgencyLevel))
                                .bold()
                        }
                        
                        Text("Note: These suggestions are for reference only. Please consult a veterinarian if concerned.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Health Advice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                do {
                    if let response = try await viewModel.getAIAdvice(symptoms: symptoms) {
                        // 创建分析记录
                        let analysis = HealthAnalysis(
                            id: UUID(),
                            date: Date(),
                            catId: viewModel.cat.id,
                            symptoms: Array(symptoms.map { $0.rawValue }),
                            possibleConditions: response.possibleConditions,
                            recommendations: response.recommendations,
                            urgencyLevel: response.urgencyLevel.rawValue,
                            catInfo: .init(
                                age: Calendar.current.dateComponents([.year], from: viewModel.cat.birthDate, to: Date()).year ?? 0,
                                weight: viewModel.cat.weight,
                                breed: viewModel.cat.breed,
                                isNeutered: viewModel.cat.isNeutered
                            )
                        )
                        
                        try await DataService.shared.saveHealthAnalysis(analysis)
                        let updatedHistory = try await DataService.shared.fetchHealthAnalyses(forCat: viewModel.cat.id)
                        await MainActor.run {
                            viewModel.analysisHistory = updatedHistory
                        }
                    }
                } catch {
                    print("❌ Error getting AI advice:", error)
                    viewModel.error = error
                }
            }
        }
    }
    
    private func urgencyColor(_ urgency: WellnessViewModel.AIResponse.UrgencyLevel) -> Color {
        switch urgency {
        case .immediate: return .red
        case .soon: return .orange
        case .monitor: return .yellow
        case .minor: return .green
        }
    }
}

// 症状泡泡视图
struct SymptomBubble: View {
    let symptom: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Text(symptom)
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1))
            .foregroundColor(isSelected ? .blue : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.3), value: isSelected)
            .onTapGesture {
                withAnimation {
                    isSelected.toggle()
                }
            }
    }
}

