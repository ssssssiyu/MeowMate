import Foundation

struct Disease: Codable {
    let name: String
    let description: String
    let recommendation: DietaryRecommendation
    
    struct DietaryRecommendation: Codable {
        let title: String
        let description: String
        let priority: Priority
        
        enum Priority: String, Codable {
            case high
            case medium
            case low
        }
    }
}

class DiseaseService {
    private let apiKey = APIConfig.openAIKey
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    func fetchDiseases() async throws -> [Disease] {
        let prompt = """
        Generate a list of 5 common cat diseases with their descriptions and dietary recommendations in JSON format:
        {
            "diseases": [
                {
                    "name": "disease name",
                    "description": "detailed description including symptoms",
                    "recommendation": {
                        "title": "dietary recommendation title",
                        "description": "detailed dietary recommendation",
                        "priority": "high"
                    }
                }
            ]
        }
        Only include diseases that can be managed through diet. Keep descriptions concise.
        """
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a veterinary nutrition expert. Respond only with the requested JSON format."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 打印响应数据以便调试
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "DiseaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "DiseaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])
        }
        
        let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
        
        guard let jsonString = chatResponse.choices.first?.message.content,
              let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "DiseaseService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        let diseaseResponse = try JSONDecoder().decode(DiseaseResponse.self, from: jsonData)
        return diseaseResponse.diseases
    }
}

// Response structures
struct ChatGPTResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct DiseaseResponse: Codable {
    let diseases: [Disease]
} 