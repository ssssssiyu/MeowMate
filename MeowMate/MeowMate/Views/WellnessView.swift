import SwiftUI

struct WellnessView: View {
    @StateObject private var viewModel: WellnessViewModel
    @AppStorage("selectedDiseases") private var selectedDiseasesStorage: String = "[]"
    @State private var selectedDiseasesList: [String] = []
    @State private var selectedDisease: String = ""
    @State private var showingDetail: Bool = false
    @State private var showClearAlert: Bool = false
    @State private var cat: Cat
    
    init(cat: Cat) {
        _viewModel = StateObject(wrappedValue: WellnessViewModel(cat: cat))
        _cat = State(initialValue: cat)
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    if !selectedDiseasesList.isEmpty {
                        Button(action: {
                            showClearAlert = true
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
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        if viewModel.diseases.isEmpty {
                            Button("Load Diseases") {
                                viewModel.loadDiseases()
                            }
                        }
                        ForEach(viewModel.diseases, id: \.name) { disease in
                            HStack {
                                Text(disease.name)
                                Spacer()
                                if selectedDiseasesList.contains(disease.name) {
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedDiseasesList.contains(disease.name) {
                                    selectedDiseasesList.removeAll { $0 == disease.name }
                                } else {
                                    selectedDiseasesList.append(disease.name)
                                }
                                if let data = try? JSONEncoder().encode(selectedDiseasesList),
                                   let string = String(data: data, encoding: .utf8) {
                                    selectedDiseasesStorage = string
                                    viewModel.selectedDiseases = selectedDiseasesList
                                    viewModel.updateHealthTips()
                                }
                            }
                            .onLongPressGesture {
                                selectedDisease = disease.name
                                showingDetail = true
                            }
                        }
                    }
                }
            }
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
            .fullScreenCover(isPresented: $showingDetail) {
                if let disease = viewModel.diseases.first(where: { $0.name == selectedDisease }) {
                    DiseaseDetailView(
                        disease: disease.name,
                        description: disease.description,
                        recommendation: disease.recommendation,
                        isPresented: $showingDetail
                    )
                }
            }
            .onAppear {
                if let diseases = try? JSONDecoder().decode([String].self, from: selectedDiseasesStorage.data(using: .utf8) ?? Data()) {
                    selectedDiseasesList = diseases
                    viewModel.selectedDiseases = diseases
                    viewModel.updateHealthTips()
                }
                viewModel.loadDiseases()  // 加载疾病数据
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
}

struct DiseasePickerView: View {
    @Binding var selectedDiseases: [String]
    let viewModel: WellnessViewModel
    let onSave: ([String]) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDetail: Bool = false
    @State private var selectedDisease: String = ""
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
                            selectedDisease = disease
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
                            Text(selectedDisease)
                                .font(.system(size: 24, weight: .bold))
                                .padding(.top)
                            
                            if let description = viewModel.localDiseases[selectedDisease] {
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
    let disease: String
    let description: String
    let recommendation: Disease.DietaryRecommendation
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(disease)
                        .font(.title)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dietary Recommendation")
                            .font(.headline)
                        Text(recommendation.title)
                            .font(.subheadline)
                            .bold()
                        Text(recommendation.description)
                            .font(.body)
                        
                        HStack {
                            Text("Priority:")
                            Text(recommendation.priority.rawValue.capitalized)
                                .foregroundColor(priorityColor(recommendation.priority))
                                .bold()
                        }
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Close") {
                isPresented = false
            })
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
