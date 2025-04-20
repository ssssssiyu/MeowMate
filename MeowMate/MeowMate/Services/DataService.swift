import Foundation
import FirebaseFirestore
import FirebaseStorage

class DataService {
    static let shared = DataService()
    private let db = FirebaseConfig.db
    private let storage = FirebaseConfig.storage
    private let deviceID = FirebaseConfig.deviceID
    
    private init() {}
    
    // 修改获取品种图片的方法
    func fetchBreedImage(breed: String) async throws -> (url: String, image: UIImage)? {
        // 1. 对品种名进行 URL 编码
        guard let encodedBreed = breed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        // 2. 获取品种信息
        let breedSearchUrl = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(encodedBreed)")!
        var request = URLRequest(url: breedSearchUrl)
        request.setValue("live_Gg8qZBEQZXvGYRyGZFXZzXkGEkxQGpVQIpWLlGXgOLgGRjmIrYgQF5wXWHhBzwbH", forHTTPHeaderField: "x-api-key")
        
        let (breedData, _) = try await URLSession.shared.data(from: request.url!)
        
        guard let breeds = try? JSONDecoder().decode([BreedInfo].self, from: breedData),
              let breedInfo = breeds.first,
              let referenceImageId = breedInfo.reference_image_id else {
            return nil
        }
        
        // 3. 获取图片 URL
        let imageUrl = URL(string: "https://api.thecatapi.com/v1/images/\(referenceImageId)")!
        request = URLRequest(url: imageUrl)
        request.setValue("live_Gg8qZBEQZXvGYRyGZFXZzXkGEkxQGpVQIpWLlGXgOLgGRjmIrYgQF5wXWHhBzwbH", forHTTPHeaderField: "x-api-key")
        
        let (imageData, _) = try await URLSession.shared.data(from: request.url!)
        
        guard let catImage = try? JSONDecoder().decode(CatImage.self, from: imageData) else {
            return nil
        }
        
        // 4. 下载实际图片
        guard let finalImageUrl = URL(string: catImage.url),
              let (finalImageData, _) = try? await URLSession.shared.data(from: finalImageUrl),
              let image = UIImage(data: finalImageData) else {
            return nil
        }
        
        return (catImage.url, image)
    }
    
    // 这些结构体可以保持 private
    private struct BreedInfo: Codable {
        let id: String
        let name: String
        let reference_image_id: String?
    }

    private struct CatImage: Codable {
        let id: String
        let url: String
        let width: Int
        let height: Int
    }
    
    // 删除所有健康分析记录
    func deleteAllHealthAnalyses(forCat catId: UUID) async throws {
        let userDefaults = UserDefaults.standard
        let key = "health_analyses_\(catId.uuidString)"
        
        // 从 UserDefaults 中删除所有健康分析记录
        userDefaults.removeObject(forKey: key)
    }
    
    // 保存健康分析记录
    func saveHealthAnalysis(_ analysis: HealthAnalysis) async throws {
        let userDefaults = UserDefaults.standard
        let key = "health_analyses_\(analysis.catId.uuidString)"
        
        // 获取现有的分析记录
        var analyses: [HealthAnalysis] = []
        if let data = userDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([HealthAnalysis].self, from: data) {
            analyses = decoded
        }
        
        // 添加新的分析记录
        analyses.append(analysis)
        
        // 保存回 UserDefaults
        if let encoded = try? JSONEncoder().encode(analyses) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    // 获取健康分析记录
    func fetchHealthAnalyses(forCat catId: UUID) async throws -> [HealthAnalysis] {
        let userDefaults = UserDefaults.standard
        let key = "health_analyses_\(catId.uuidString)"
        
        if let data = userDefaults.data(forKey: key),
           let analyses = try? JSONDecoder().decode([HealthAnalysis].self, from: data) {
            return analyses.sorted { $0.date > $1.date }
        }
        
        return []
    }
} 
