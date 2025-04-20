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
            HealthAnalysisTab(viewModel: viewModel, showingResetAlert: $showingResetAlert, cat: cat)
                .tag(0)
            
            DiseaseLibraryTab(viewModel: viewModel, selectedDisease: $selectedDisease)
                .tag(1)
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
        if let encodedData = try? JSONEncoder().encode(selectedDiseasesList) {
            UserDefaults.standard.set(String(data: encodedData, encoding: .utf8), forKey: "selectedDiseases")
        }
    }
}

// 健康分析标签页
struct HealthAnalysisTab: View {
    let viewModel: WellnessViewModel
    @Binding var showingResetAlert: Bool
    let cat: Cat
    
    var body: some View {
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
        .navigationTitle("Health Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Theme.Text.navigationTitle("Health Analysis")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingResetAlert = true
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.primary)
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
                        viewModel.error = error
                    }
                }
            }
        } message: {
            Text("This will delete all health analysis history. This action cannot be undone.")
        }
    }
}

// 疾病库标签页
struct DiseaseLibraryTab: View {
    let viewModel: WellnessViewModel
    @Binding var selectedDisease: Disease?
    
    var body: some View {
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
        .navigationTitle("Disease Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Theme.Text.navigationTitle("Disease Library")
            }
        }
    }
    
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
                .foregroundColor(Theme.mintGreen)
            Text(category.rawValue)
                .foregroundColor(Theme.mintGreen)
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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 标题部分
                        Text(disease.name)
                            .font(.system(size: 24))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        
                        // 描述部分
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: disease.category.systemImage)
                                    .foregroundColor(Theme.mintGreen)
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(Theme.mintGreen)
                            }
                            Text(disease.description)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        
                        // 症状部分
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(Theme.mintGreen)
                                Text("Symptoms")
                                    .font(.headline)
                                    .foregroundColor(Theme.mintGreen)
                            }
                            ForEach(disease.symptoms, id: \.self) { symptom in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(Theme.mintGreen)
                                    Text(symptom)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        
                        // 建议部分
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "heart.text.square")
                                    .foregroundColor(Theme.mintGreen)
                                Text("Advice")
                                    .font(.headline)
                                    .foregroundColor(Theme.mintGreen)
                            }
                            Text(disease.recommendation.title)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                            Text(disease.recommendation.description)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Priority:")
                                    .foregroundColor(.primary)
                                Text(disease.recommendation.priority.rawValue.capitalized)
                                    .foregroundColor(priorityColor(disease.recommendation.priority))
                                    .bold()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.mintGreen)
                }
            }
        }
    }
    
    private func priorityColor(_ priority: Disease.CareAdvice.Priority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return Theme.mintGreen
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
            .background(isSelected ? Theme.mintGreen.opacity(0.3) : Theme.mintGreen.opacity(0.1))
            .foregroundColor(isSelected ? Theme.mintGreen : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Theme.mintGreen : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .animation(.spring(response: 0.3), value: isSelected)
            .onTapGesture {
                withAnimation {
                    isSelected.toggle()
                }
            }
    }
}

#Preview {
    NavigationView {
        WellnessView(
            cat: Cat(
                id: UUID(),
                name: "Luna",
                breed: "British Shorthair",
                birthDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
                gender: .female,
                weight: 4.5,
                weightHistory: [
                    WeightRecord(id: UUID(), date: Date().addingTimeInterval(-7*24*3600), weight: 4.2),
                    WeightRecord(id: UUID(), date: Date(), weight: 4.5)
                ],
                isNeutered: true,
                image: nil,
                imageURL: nil
            )
        )
    }
}

