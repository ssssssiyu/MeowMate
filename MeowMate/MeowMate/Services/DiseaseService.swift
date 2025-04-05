import Foundation

class DiseaseService {
    private let apiKey = APIConfig.openAIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // 预设的常见疾病列表
    public let commonDiseases: [Disease] = [
        // 消化系统
        Disease(
            name: "Hairballs",
            description: "Common in cats, especially long-haired breeds.",
            symptoms: ["Vomiting", "Lethargy", "Loss of appetite", "Constipation"],
            category: .digestive,
            recommendation: .init(
                title: "Grooming and Diet Management",
                description: "Regular brushing and specialized hairball control food",
                priority: .low
            )
        ),
        Disease(
            name: "Inflammatory Bowel Disease",
            description: "A group of chronic gastrointestinal disorders.",
            symptoms: ["Chronic vomiting", "Diarrhea", "Weight loss", "Poor appetite"],
            category: .digestive,
            recommendation: .init(
                title: "Diet Modification",
                description: "Hypoallergenic food, easily digestible diet",
                priority: .high
            )
        ),
        Disease(
            name: "Gastritis",
            description: "Inflammation of the stomach lining causing digestive issues.",
            symptoms: ["Vomiting", "Decreased appetite", "Weight loss", "Abdominal pain"],
            category: .digestive,
            recommendation: .init(
                title: "Gastric Support",
                description: "Bland diet, small frequent meals",
                priority: .medium
            )
        ),
        
        // 泌尿系统
        Disease(
            name: "Urinary Tract Infection",
            description: "Bacterial infection affecting the urinary system.",
            symptoms: ["Frequent urination", "Blood in urine", "Straining to urinate"],
            category: .urinary,
            recommendation: .init(
                title: "Urinary Health",
                description: "Increase water intake, special urinary diet",
                priority: .high
            )
        ),
        Disease(
            name: "Kidney Stones",
            description: "Mineral deposits that can block urinary tract.",
            symptoms: ["Pain", "Blood in urine", "Reduced urination"],
            category: .urinary,
            recommendation: .init(
                title: "Stone Prevention",
                description: "Special diet to prevent stone formation",
                priority: .high
            )
        ),
        Disease(
            name: "Bladder Crystals",
            description: "Microscopic crystals in urine that can cause discomfort.",
            symptoms: ["Frequent urination", "Urinating outside litter box", "Discomfort"],
            category: .urinary,
            recommendation: .init(
                title: "Crystal Management",
                description: "pH-balanced diet, increased water intake",
                priority: .medium
            )
        ),
        
        // 呼吸系统
        Disease(
            name: "Upper Respiratory Infection",
            description: "Common viral or bacterial infections affecting the respiratory system.",
            symptoms: ["Sneezing", "Runny nose", "Watery eyes", "Loss of appetite", "Fever"],
            category: .respiratory,
            recommendation: .init(
                title: "Respiratory Support",
                description: "Easily digestible food, increased fluid intake",
                priority: .high
            )
        ),
        Disease(
            name: "Asthma",
            description: "Chronic inflammation of airways causing breathing difficulties.",
            symptoms: ["Coughing", "Wheezing", "Difficulty breathing", "Open-mouth breathing"],
            category: .respiratory,
            recommendation: .init(
                title: "Respiratory Care",
                description: "Low-dust diet and environment, omega-3 supplements",
                priority: .high
            )
        ),
        Disease(
            name: "Bronchitis",
            description: "Inflammation of the bronchi causing respiratory issues.",
            symptoms: ["Persistent cough", "Breathing difficulty", "Lethargy", "Reduced appetite"],
            category: .respiratory,
            recommendation: .init(
                title: "Bronchial Support",
                description: "Soft, moist food and immune-supporting supplements",
                priority: .medium
            )
        ),
        
        // 皮肤问题
        Disease(
            name: "Skin Allergies",
            description: "Allergic reactions can cause skin problems and discomfort.",
            symptoms: ["Excessive scratching", "Hair loss", "Red skin", "Scabs"],
            category: .skin,
            recommendation: .init(
                title: "Allergy Management",
                description: "Hypoallergenic diet, regular grooming",
                priority: .medium
            )
        ),
        Disease(
            name: "Food Allergies",
            description: "Allergic reactions to specific food ingredients.",
            symptoms: ["Itching", "Skin redness", "Hair loss", "Ear infections"],
            category: .skin,
            recommendation: .init(
                title: "Allergy Management",
                description: "Hypoallergenic diet, elimination trial",
                priority: .medium
            )
        ),
        Disease(
            name: "Flea Allergy Dermatitis",
            description: "Severe allergic reaction to flea bites.",
            symptoms: ["Intense itching", "Scabs", "Hair loss", "Skin inflammation"],
            category: .skin,
            recommendation: .init(
                title: "Skin Health",
                description: "Anti-inflammatory diet, omega-3 supplements",
                priority: .medium
            )
        ),
        Disease(
            name: "Atopic Dermatitis",
            description: "Environmental allergies affecting the skin.",
            symptoms: ["Chronic itching", "Face rubbing", "Excessive grooming", "Skin lesions"],
            category: .skin,
            recommendation: .init(
                title: "Skin Support",
                description: "Skin-supporting supplements, balanced diet",
                priority: .medium
            )
        ),
        
        // 牙齿健康
        Disease(
            name: "Dental Disease",
            description: "Periodontal disease is one of the most common health issues in cats.",
            symptoms: ["Bad breath", "Drooling", "Difficulty eating", "Red or swollen gums"],
            category: .dental,
            recommendation: .init(
                title: "Dental Health",
                description: "Dental treats, specialized dental diet",
                priority: .medium
            )
        ),
        Disease(
            name: "Gingivitis",
            description: "Early stage gum disease causing inflammation.",
            symptoms: ["Red gums", "Bleeding gums", "Bad breath", "Drooling"],
            category: .dental,
            recommendation: .init(
                title: "Gum Health",
                description: "Dental-specific dry food, enzymatic treats",
                priority: .medium
            )
        ),
        Disease(
            name: "Tooth Resorption",
            description: "Progressive destruction of tooth structure.",
            symptoms: ["Difficulty eating", "Mouth pain", "Drooling", "Bleeding"],
            category: .dental,
            recommendation: .init(
                title: "Dental Care",
                description: "Soft food diet, calcium supplements",
                priority: .high
            )
        ),
        
        // 代谢疾病
        Disease(
            name: "Diabetes",
            description: "A serious condition requiring careful management of diet and insulin.",
            symptoms: ["Increased thirst", "Frequent urination", "Weight loss", "Increased appetite"],
            category: .metabolic,
            recommendation: .init(
                title: "Diabetes Management",
                description: "Special diabetic diet, regular feeding schedule",
                priority: .high
            )
        ),
        Disease(
            name: "Obesity",
            description: "Excessive body weight affecting overall health.",
            symptoms: ["Weight gain", "Reduced activity", "Difficulty grooming", "Joint stress"],
            category: .metabolic,
            recommendation: .init(
                title: "Weight Management",
                description: "Portion-controlled diet, low-calorie food",
                priority: .medium
            )
        ),
        Disease(
            name: "Hyperthyroidism",
            description: "Overactive thyroid causing increased metabolism.",
            symptoms: ["Weight loss", "Increased appetite", "Hyperactivity", "Vomiting"],
            category: .metabolic,
            recommendation: .init(
                title: "Thyroid Management",
                description: "Iodine-controlled diet, frequent small meals",
                priority: .high
            )
        ),
        
        // 关节和行动能力
        Disease(
            name: "Arthritis",
            description: "Common in older cats, affecting mobility and quality of life.",
            symptoms: ["Difficulty jumping", "Limping", "Reduced activity", "Irritability when touched"],
            category: .musculoskeletal,
            recommendation: .init(
                title: "Joint Support",
                description: "Joint supplements, easy access to resources",
                priority: .medium
            )
        ),
        Disease(
            name: "Hip Dysplasia",
            description: "Developmental condition affecting hip joints.",
            symptoms: ["Limping", "Reduced jumping", "Difficulty climbing", "Pain"],
            category: .musculoskeletal,
            recommendation: .init(
                title: "Joint Support",
                description: "Glucosamine supplements, omega-3 rich diet",
                priority: .medium
            )
        ),
        Disease(
            name: "Osteoarthritis",
            description: "Degenerative joint disease common in older cats.",
            symptoms: ["Joint stiffness", "Reduced mobility", "Pain", "Behavioral changes"],
            category: .musculoskeletal,
            recommendation: .init(
                title: "Arthritis Care",
                description: "Anti-inflammatory diet, joint supplements",
                priority: .high
            )
        )
    ]
    
    func fetchDiseases() async throws -> [Disease] {
        let prompt = """
        Return ONLY the JSON data in this exact format, with no other text:
        {
            "diseases": [
                {
                    "id": "UUID string",
                    "name": "disease name",
                    "description": "detailed description",
                    "symptoms": ["symptom1", "symptom2"],
                    "category": "Digestive System",
                    "recommendation": {
                        "title": "dietary recommendation title",
                        "description": "detailed dietary recommendation",
                        "priority": "high"
                    }
                }
            ]
        }
        
        Categories: "Digestive System", "Urinary System", "Respiratory System", "Skin & Coat", "Dental Health", "Metabolic Disorders", "Joints & Mobility"
        Priorities: "high", "medium", "low"
        Generate 5 common cat diseases that can be managed through diet.
        """
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": APIConfig.OpenAI.model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a JSON-only response bot. Never include any explanatory text, markdown, or prefixes. Only return valid JSON data."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 调试日志
        print("Response Headers:", (response as? HTTPURLResponse)?.allHeaderFields ?? [:])
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw API Response:", responseString)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "DiseaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
            )
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(
                domain: "DiseaseService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"]
            )
        }
        
        // 尝试清理响应数据
        let chatResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(
                domain: "DiseaseService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No content in response"]
            )
        }
        
        // 尝试从内容中提取纯 JSON
        let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonStart = cleanedContent.firstIndex(of: "{"),
              let jsonEnd = cleanedContent.lastIndex(of: "}") else {
            throw NSError(
                domain: "DiseaseService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Could not find JSON content"]
            )
        }
        
        let jsonString = String(cleanedContent[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "DiseaseService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Could not convert content to data"]
            )
        }
        
        do {
            let diseaseResponse = try JSONDecoder().decode(OpenAIDiseaseResponse.self, from: jsonData)
            return diseaseResponse.diseases
        } catch {
            print("JSON Decoding Error:", error)
            print("Attempted to decode:", jsonString)
            throw NSError(
                domain: "DiseaseService",
                code: -5,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode disease data: \(error.localizedDescription)"]
            )
        }
    }
} 