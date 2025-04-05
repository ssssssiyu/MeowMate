import Foundation
import SwiftUI

@MainActor
class WellnessViewModel: ObservableObject {
    let cat: Cat
    @Published var selectedDiseases: [String] = []
    @Published var selectedSymptoms: Set<CommonSymptoms> = []
    @Published var healthTips: [String] = []
    @Published var diseases: [Disease] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var aiResponse: AIResponse?
    @Published var showingAIAdvice = false
    @Published var analysisHistory: [HealthAnalysis] = []
    @Published var showingHistoricalAnalysis = false
    @Published var selectedHistoricalAnalysis: HealthAnalysis?
    
    struct AIResponse: Codable {
        let possibleConditions: [String]
        let recommendations: [String]
        let urgencyLevel: UrgencyLevel
        
        enum UrgencyLevel: String, Codable {
            case immediate = "Immediate Care"
            case soon = "Urgent Care"
            case monitor = "Monitor"
            case minor = "Home Care"
        }
    }
    
    let localDiseases: [String: String] = [
        "Blood in Urine": """
            Blood in urine is a concerning symptom that may indicate:
            
            1. Urinary Tract Infection (UTI)
            - One of the most common causes
            - May be accompanied by difficulty and frequent urination
            
            2. Stones
            - Bladder or kidney stones
            - Usually accompanied by pain
            
            3. Trauma or Inflammation
            - Can be caused by external injury or internal inflammation
            
            Recommended Actions:
            • Ensure your cat has plenty of water
            • Keep the litter box clean
            • Seek veterinary care for proper diagnosis
            • Follow prescribed treatment
            
            Note: If a kitten has blood in urine, it's more urgent - seek immediate veterinary care!
            """,
        
        "Vomiting": """
            Vomiting can be caused by various factors:
            
            Common Causes:
            1. Hairball Issues
            - More common in long-haired cats
            - Can be prevented with special supplements
            
            2. Dietary Issues
            - Consuming inappropriate food
            - Eating too quickly
            - Food too cold or spoiled
            
            3. Digestive System Diseases
            - Gastritis
            - Enteritis
            - Food allergies
            
            Recommended Actions:
            • Withhold food for 4-6 hours
            • Feed small portions more frequently
            • Provide fresh water
            • Avoid sudden changes in diet
            
            When to See a Vet:
            - Vomiting persists over 24 hours
            - Accompanied by lethargy
            - Combined with diarrhea or fever
            """,
        
        "Diarrhea": """
            Diarrhea is a common digestive symptom to monitor:
            
            Possible Causes:
            1. Dietary Changes
            - Sudden change in cat food
            - Consuming inappropriate food
            
            2. Parasitic Infections
            - Worms
            - Protozoa like Giardia
            
            3. Bacterial or Viral Infections
            - Salmonella
            - Coronavirus
            
            4. Chronic Conditions
            - Inflammatory bowel disease
            - Food allergies
            
            Recommended Actions:
            • Withhold food for 12 hours
            • Provide plenty of water
            • Use easily digestible food
            • Maintain clean environment
            
            Warning Signs:
            - Persists over 48 hours
            - Blood in stool
            - Poor general condition
            - Fever or vomiting
            
            Seek veterinary care if any warning signs appear!
            """
    ]
    
    let diseaseDatabase: [String: Disease] = [
        "Blood in Urine": Disease(
            name: "Blood in Urine",
            description: "Blood in urine is a concerning symptom that requires attention.",
            symptoms: ["Blood in urine", "Frequent urination", "Pain while urinating"],
            category: .urinary,
            recommendation: .init(
                title: "Urinary Health",
                description: "Ensure adequate water intake, monitor for 24 hours.",
                priority: .high
            )
        ),
        
        "Vomiting": Disease(
            name: "Vomiting",
            description: "A common symptom that can indicate various health issues.",
            symptoms: ["Vomiting", "Loss of appetite", "Lethargy"],
            category: .digestive,
            recommendation: .init(
                title: "Digestive Care",
                description: "Withhold food for 4-6 hours, provide fresh water.",
                priority: .medium
            )
        ),
        
        "Diarrhea": Disease(
            name: "Diarrhea",
            description: "A digestive issue that requires monitoring and dietary adjustment.",
            symptoms: ["Diarrhea", "Frequent bowel movements", "Loose stools"],
            category: .digestive,
            recommendation: .init(
                title: "Digestive Support",
                description: "Provide easily digestible food, monitor for 24 hours.",
                priority: .medium
            )
        )
    ]
    
    let diseaseOptions: [String: (String) -> String] = [
        "Blood in Urine": { age in age == "Kitten" ? "Seek immediate veterinary care! More dangerous for kittens!" : "Ensure adequate water intake, monitor for 24 hours." },
        "Vomiting": { age in age == "Adult" ? "Reduce dry food, provide more water." : "Might be hairballs, try hairball treatment." },
        "Diarrhea": { _ in "Provide easily digestible food, monitor for 24 hours." }
    ]
    
    var catAge: String {
        let age = Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0
        return age < 1 ? "Kitten" : "Adult"
    }
    
    let diseaseService = DiseaseService()
    
    init(cat: Cat) {
        self.cat = cat
        self.diseases = diseaseService.commonDiseases
        
        // 设置实时监听
        setupAnalysisListener()
    }
    
    private func setupAnalysisListener() {
        Task {
            do {
                try await DataService.shared.listenToHealthAnalyses(forCat: cat.id) { [weak self] analyses in
                    Task { @MainActor in
                        self?.analysisHistory = analyses
                    }
                }
            } catch {
                print("❌ Failed to setup analysis listener:", error)
                self.error = error
            }
        }
    }
    
    func updateHealthTips() {
        healthTips = selectedDiseases.compactMap { diseaseOptions[$0]?(catAge) }
    }
    
    func loadDiseases() {
        // 直接使用预设数据，不调用 API
        self.diseases = diseaseService.commonDiseases
        self.isLoading = false
    }
    
    // 只在用户请求时调用 AI
    func requestAIAdvice() {
        showingAIAdvice = true
    }
    
    func getAIAdvice(symptoms: Set<CommonSymptoms>) async throws -> AIResponse? {
        isLoading = true
        defer { isLoading = false }
        
        let symptomStrings = symptoms.map { $0.rawValue }
        
        // 创建历史记录上下文，只包含最近两周的记录
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentHistory = analysisHistory
            .filter { $0.date > twoWeeksAgo }  // 只保留两周内的记录
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { analysis in
                """
                Previous Analysis (\(formatDate(analysis.date))):
                - Symptoms: \(analysis.symptoms.joined(separator: ", "))
                - Diagnosed Conditions: \(analysis.possibleConditions.joined(separator: ", "))
                - Urgency Level: \(analysis.urgencyLevel)
                - Weight Then: \(String(format: "%.1f", analysis.catInfo.weight)) kg
                """
            }
            .joined(separator: "\n\n")
        
        let historyContext = recentHistory.isEmpty ? "No recent health records in the past two weeks." : recentHistory
        
        // 添加常见病症参考
        let commonConditionsReference = diseaseDatabase.values
            .map { disease in
                """
                \(disease.name):
                - Symptoms: \(disease.symptoms.joined(separator: ", "))
                - Priority: \(disease.recommendation.priority.rawValue)
                """
            }
            .joined(separator: "\n\n")
        
        let prompt = """
        You are a veterinary expert. Analyze the following symptoms and provide a professional diagnosis.
        
        Common Feline Conditions Reference:
        \(commonConditionsReference)
        
        Cat Information:
        - Age: \(Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0) years
        - Breed: \(cat.breed)
        - Weight: \(String(format: "%.1f", cat.weight)) kg
        - Gender: \(cat.gender.rawValue)
        - Neutered Status: \(cat.isNeutered ? "Neutered" : "Not Neutered")
        
        Medical History:
        \(historyContext)
        
        Current Symptoms:
        \(symptomStrings.joined(separator: "\n"))
        
        Instructions:
        1. Analyze the symptoms and identify possible underlying medical conditions (not the symptoms themselves)
        2. Common symptom combinations to consider:
           - Coughing + Drooling: May indicate respiratory infection, oral disease, or foreign body
           - Vomiting + Lethargy: Could suggest gastritis, poisoning, or systemic illness
           - Urinary changes + Crying: Often related to urinary tract issues or bladder stones
           
        3. For each condition consider:
           - Primary symptoms present
           - Age-related risks
           - Breed predispositions
           - Medical history patterns
        
        4. Urgency levels:
           - Immediate Care: Life-threatening (breathing difficulty, severe bleeding, poisoning)
           - Urgent Care: Needs vet within 24-48 hours (severe pain, persistent vomiting)
           - Monitor: Watch closely (mild symptoms, eating/drinking normally)
           - Home Care: Minor issues manageable at home
        
        5. Recommendations should be specific and actionable, such as:
           - "Monitor breathing rate and seek vet if exceeds 40 breaths per minute"
           - "Keep cat in cool environment and ensure fresh water access"
           - "Book vet appointment within 24 hours for proper examination"
        
        Respond with a JSON object in exactly this format:
        {
            "possibleConditions": ["Specific medical conditions, not symptoms"],
            "recommendations": ["Clear, actionable advice"],
            "urgencyLevel": "One of the four levels above"
        }
        """
        
        do {
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(APIConfig.openAIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "model": APIConfig.OpenAI.model,
                "messages": [
                    ["role": "system", "content": "You are a professional veterinarian. Only respond with the exact JSON format specified. No other text."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.3  // 降低温度以获得更一致的输出
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // 添加调试信息
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            if let content = response.choices.first?.message.content {
                print("GPT Content: \(content)")
                
                if let jsonData = content.data(using: .utf8),
                   let aiResponse = try? JSONDecoder().decode(AIResponse.self, from: jsonData) {
                    await MainActor.run {
                        self.aiResponse = aiResponse
                    }
                    return aiResponse
                }
            }
        } catch {
            print("❌ AI API Error: \(error)")
            self.error = error
        }
        
        return nil
    }
    
    private func formatWeightHistory() -> String {
        let sortedHistory = cat.weightHistory
            .sorted { $0.date > $1.date }
            .prefix(3)  // 最近的3次记录
            .map { record in
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                return "\(dateFormatter.string(from: record.date)): \(record.weight)kg"
            }
            .joined(separator: ", ")
        
        return sortedHistory.isEmpty ? "No weight history" : sortedHistory
    }
    
    private func createHistoryContext() -> String {
        let recentHistory = analysisHistory
            .sorted { $0.date > $1.date }
            .prefix(3)  // 最近的3次记录
            .map { analysis in
                """
                Analysis on \(formatDate(analysis.date)):
                - Symptoms: \(analysis.symptoms.joined(separator: ", "))
                - Diagnosed Conditions: \(analysis.possibleConditions.joined(separator: ", "))
                - Urgency Level: \(analysis.urgencyLevel)
                - Cat's Weight Then: \(analysis.catInfo.weight) kg
                """
            }
            .joined(separator: "\n\n")
        
        return recentHistory.isEmpty ? "No previous health records." : recentHistory
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func isSymptomSelected(_ symptom: CommonSymptoms) -> Binding<Bool> {
        Binding(
            get: { self.selectedSymptoms.contains(symptom) },
            set: { isSelected in
                if isSelected {
                    self.selectedSymptoms.insert(symptom)
                } else {
                    self.selectedSymptoms.remove(symptom)
                }
            }
        )
    }
    
    func showHistoricalAnalysis(_ analysis: HealthAnalysis) {
        selectedHistoricalAnalysis = analysis
        showingHistoricalAnalysis = true
    }
} 