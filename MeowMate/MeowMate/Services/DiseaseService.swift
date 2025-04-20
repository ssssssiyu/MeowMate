import Foundation

class DiseaseService {
    private let apiKey = APIConfig.openAIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    // 预设的常见疾病列表
    public let commonDiseases: [Disease] = [
        // 消化系统
        Disease(
            name: "Hairball Syndrome",
            description: "More frequent in long-haired breeds, causing digestive discomfort.",
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
                title: "Diet and Medication",
                description: "Hypoallergenic food and prescribed medications as needed",
                priority: .high
            )
        ),
        Disease(
            name: "Gastritis",
            description: "Inflammation of the stomach lining causing digestive issues.",
            symptoms: ["Vomiting", "Decreased appetite", "Weight loss", "Abdominal pain"],
            category: .digestive,
            recommendation: .init(
                title: "Rest and Diet Control",
                description: "Small frequent meals and temporary fasting if recommended",
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
                title: "Hydration and Treatment",
                description: "Increase water intake and complete prescribed antibiotics",
                priority: .high
            )
        ),
        Disease(
            name: "Kidney Stones",
            description: "Mineral deposits that can block urinary tract.",
            symptoms: ["Pain", "Blood in urine", "Reduced urination"],
            category: .urinary,
            recommendation: .init(
                title: "Prevention and Care",
                description: "Special diet, increased water intake, and regular check-ups",
                priority: .high
            )
        ),
        Disease(
            name: "Bladder Crystals",
            description: "Microscopic crystals in urine that can cause discomfort.",
            symptoms: ["Frequent urination", "Urinating outside litter box", "Discomfort"],
            category: .urinary,
            recommendation: .init(
                title: "Diet and Environment",
                description: "pH-balanced diet and clean, accessible litter boxes",
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
                title: "Rest and Support",
                description: "Keep warm, clean nose/eyes, and maintain good nutrition",
                priority: .high
            )
        ),
        Disease(
            name: "Asthma",
            description: "Chronic inflammation of airways causing breathing difficulties.",
            symptoms: ["Coughing", "Wheezing", "Difficulty breathing", "Open-mouth breathing"],
            category: .respiratory,
            recommendation: .init(
                title: "Environment and Treatment",
                description: "Reduce triggers, maintain clean air, and follow medication plan",
                priority: .high
            )
        ),
        Disease(
            name: "Bronchitis",
            description: "Inflammation of the bronchi causing respiratory issues.",
            symptoms: ["Persistent cough", "Breathing difficulty", "Lethargy", "Reduced appetite"],
            category: .respiratory,
            recommendation: .init(
                title: "Rest and Treatment",
                description: "Humidified environment and prescribed medications",
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
                title: "Environment and Diet",
                description: "Identify triggers, regular grooming, and special diet",
                priority: .medium
            )
        ),
        Disease(
            name: "Food Allergies",
            description: "Allergic reactions to specific food ingredients.",
            symptoms: ["Itching", "Skin redness", "Hair loss", "Ear infections"],
            category: .skin,
            recommendation: .init(
                title: "Diet Management",
                description: "Elimination diet trial and avoid identified triggers",
                priority: .medium
            )
        ),
        Disease(
            name: "Flea Allergy Dermatitis",
            description: "Severe allergic reaction to flea bites.",
            symptoms: ["Intense itching", "Scabs", "Hair loss", "Skin inflammation"],
            category: .skin,
            recommendation: .init(
                title: "Prevention and Treatment",
                description: "Regular flea prevention and environmental cleaning",
                priority: .medium
            )
        ),
        Disease(
            name: "Atopic Dermatitis",
            description: "Environmental allergies affecting the skin.",
            symptoms: ["Chronic itching", "Face rubbing", "Excessive grooming", "Skin lesions"],
            category: .skin,
            recommendation: .init(
                title: "Environment and Care",
                description: "Reduce allergens and maintain skin barrier health",
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
                title: "Dental Care",
                description: "Regular teeth cleaning and dental health monitoring",
                priority: .medium
            )
        ),
        Disease(
            name: "Gingivitis",
            description: "Early stage gum disease causing inflammation.",
            symptoms: ["Red gums", "Bleeding gums", "Bad breath", "Drooling"],
            category: .dental,
            recommendation: .init(
                title: "Oral Health",
                description: "Daily oral care and professional cleaning when needed",
                priority: .medium
            )
        ),
        Disease(
            name: "Tooth Resorption",
            description: "Progressive destruction of tooth structure.",
            symptoms: ["Difficulty eating", "Mouth pain", "Drooling", "Bleeding"],
            category: .dental,
            recommendation: .init(
                title: "Pain Management",
                description: "Soft food and dental treatment as recommended",
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
                title: "Daily Management",
                description: "Regular insulin, consistent feeding schedule, and monitoring",
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
                description: "Portion control and increased physical activity",
                priority: .medium
            )
        ),
        Disease(
            name: "Hyperthyroidism",
            description: "Overactive thyroid causing increased metabolism.",
            symptoms: ["Weight loss", "Increased appetite", "Hyperactivity", "Vomiting"],
            category: .metabolic,
            recommendation: .init(
                title: "Treatment Plan",
                description: "Medication, diet adjustment, and regular monitoring",
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
                title: "Comfort and Support",
                description: "Easy access to resources and pain management",
                priority: .medium
            )
        ),
        Disease(
            name: "Hip Dysplasia",
            description: "Developmental condition affecting hip joints.",
            symptoms: ["Limping", "Reduced jumping", "Difficulty climbing", "Pain"],
            category: .musculoskeletal,
            recommendation: .init(
                title: "Activity Management",
                description: "Gentle exercise and environmental modifications",
                priority: .medium
            )
        ),
        Disease(
            name: "Osteoarthritis",
            description: "Degenerative joint disease common in older cats.",
            symptoms: ["Joint stiffness", "Reduced mobility", "Pain", "Behavioral changes"],
            category: .musculoskeletal,
            recommendation: .init(
                title: "Pain and Mobility",
                description: "Pain relief, comfortable resting areas, and easy access",
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
            throw NSError(
                domain: "DiseaseService",
                code: -5,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode disease data: \(error.localizedDescription)"]
            )
        }
    }
} 