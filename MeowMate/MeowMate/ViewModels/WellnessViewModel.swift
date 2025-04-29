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
        loadAnalysisHistory()
    }
    
    private func loadAnalysisHistory() {
        let key = "analysis_history_\(cat.id.uuidString)"
        if let data = UserDefaults.standard.data(forKey: key),
           let history = try? JSONDecoder().decode([HealthAnalysis].self, from: data) {
            // 按日期排序，最新的在前面
            self.analysisHistory = history.sorted { $0.date > $1.date }
            
            // 只保留最近5条记录
            if self.analysisHistory.count > 5 {
                self.analysisHistory = Array(self.analysisHistory.prefix(5))
                saveAnalysisHistory()  // 保存更新后的记录
            }
        }
    }
    
    private func saveAnalysisHistory() {
        let key = "analysis_history_\(cat.id.uuidString)"
        if let data = try? JSONEncoder().encode(analysisHistory) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func addAnalysis(_ analysis: HealthAnalysis) {
        // 添加新记录到开头
        analysisHistory.insert(analysis, at: 0)
        
        // 只保留最近5条记录
        if analysisHistory.count > 5 {
            analysisHistory = Array(analysisHistory.prefix(5))
        }
        
        saveAnalysisHistory()
    }
    
    // 获取最近一个月的健康记录
    func getRecentHealthRecords() -> [HealthAnalysis] {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return analysisHistory.filter { $0.date >= oneMonthAgo }
    }
    
    // 删除所有健康分析记录
    func deleteAllAnalyses() {
        let key = "analysis_history_\(cat.id.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
        analysisHistory = []
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
        
        // 检查 API 密钥
        let apiKey = Config.API.openAIKey
        if apiKey.isEmpty {
            print("❌ OpenAI API key is empty")
            throw NSError(domain: "WellnessViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is not configured"])
        }
        
        let symptomStrings = symptoms.map { $0.rawValue }
        
        // 创建历史记录上下文，只包含最近两周的记录
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentHistory = analysisHistory
            .filter { $0.date > twoWeeksAgo }  // 只保留两周内的记录
            .sorted { $0.date > $1.date }
            .prefix(5)  // 使用所有存储的记录（最多5条）
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
        
        2. Consider breed-specific risks:
           - Persian/Himalayan: More susceptible to respiratory issues and eye problems
           - Maine Coon: Higher risk of heart disease and hip dysplasia
           - Siamese: More prone to respiratory issues and dental problems
           - British Shorthair: Higher risk of hypertrophic cardiomyopathy
           
        3. Consider gender and neutering status:
           - Unneutered Males: Higher risk of urinary blockages and territorial behavior
           - Unneutered Females: Risk of pyometra and reproductive issues
           - All unneutered: Higher risk of certain cancers
           
        4. Weight-related considerations:
           - Underweight (BMI < 18): Increase urgency for appetite and digestive issues
           - Overweight (BMI > 25): Higher risk for diabetes, joint problems
           - Sudden weight changes: Increase urgency level
           
        5. Age-specific risks:
           - Kittens (< 1 year): More vulnerable to infections, parasites
           - Adults (1-7 years): Monitor for breed-specific conditions
           - Seniors (> 7 years): Higher risk of chronic diseases
        
        6. Common symptom combinations to consider:
           - Coughing + Drooling: May indicate respiratory infection, oral disease, or foreign body
           - Vomiting + Lethargy: Could suggest gastritis, poisoning, or systemic illness
           - Urinary changes + Crying: Often related to urinary tract issues or bladder stones
           
        7. Urgency levels:
           - Immediate Care: Life-threatening (breathing difficulty, severe bleeding, poisoning)
           - Urgent Care: Needs vet within 24-48 hours (severe pain, persistent vomiting, multiple concerning symptoms)
           - Monitor: Watch closely (mild symptoms, single non-severe symptom, eating/drinking normally)
           - Home Care: Minor issues manageable at home
        
        Single symptoms severity guide:
        - Immediate Care: Difficulty breathing, severe bleeding, collapse, continuous seizures
        - Urgent Care: High fever (over 103°F/39.4°C), severe persistent vomiting (>24h), inability to urinate
        - Monitor: Mild fever, occasional vomiting, blood in urine, diarrhea, lethargy
        - Home Care: Drooling, mild coughing, sneezing, mild limping, bad breath, itchy skin, runny nose

        Symptom combinations that increase urgency:
        - Difficulty breathing + Any other symptom -> Immediate Care
        - Vomiting + Lethargy + Loss of appetite -> Urgent Care
        - Blood in urine + Difficulty urinating -> Urgent Care
        - Single mild symptom -> Home Care
        - Two mild symptoms -> Monitor
        
        8. Recommendations should be specific and actionable, such as:
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
            guard let url = URL(string: Config.API.OpenAI.endpoint) else {
                throw NSError(domain: "WellnessViewModel", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI endpoint URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "model": Config.API.OpenAI.model,
                "messages": [
                    ["role": "system", "content": "You are a professional veterinarian. Only respond with the exact JSON format specified. No other text."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.3
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "WellnessViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                }
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            if let content = openAIResponse.choices.first?.message.content {
                if let jsonData = content.data(using: .utf8),
                   let aiResponse = try? JSONDecoder().decode(AIResponse.self, from: jsonData) {
                    await MainActor.run {
                        self.aiResponse = aiResponse
                    }
                    return aiResponse
                } else {
                    throw NSError(domain: "WellnessViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode AI response"])
                }
            } else {
                throw NSError(domain: "WellnessViewModel", code: -3, userInfo: [NSLocalizedDescriptionKey: "No content in OpenAI response"])
            }
        } catch {
            self.error = error
            throw error
        }
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
            .prefix(5)  // 使用所有存储的记录（最多5条）
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