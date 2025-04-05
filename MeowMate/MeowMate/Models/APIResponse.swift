import Foundation

// OpenAI API Response structures
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

// Disease API Response structures
struct OpenAIDiseaseResponse: Codable {
    let diseases: [Disease]
}

// 其他 API 响应结构体可以在这里添加 