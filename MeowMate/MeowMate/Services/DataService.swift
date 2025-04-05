import Foundation
import FirebaseFirestore
import FirebaseStorage

class DataService {
    static let shared = DataService()
    private let db = FirebaseConfig.db
    private let storage = FirebaseConfig.storage
    private let deviceID = FirebaseConfig.deviceID
    
    private init() {}
    
    func saveCats(_ newCats: [Cat]) async throws {
        print("📝 Saving cats...")
        
        // 处理新猫咪的图片
        var catsToSave: [Cat] = []
        for var cat in newCats {
            if let image = cat.image, cat.imageURL == nil {
                cat.imageURL = try await uploadImage(image, catId: cat.id)
            }
            catsToSave.append(cat)
        }
        
        // 直接保存传入的猫咪列表
        let data = try JSONEncoder().encode(catsToSave)
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert cats to JSON"])
        }
        
        try await db.collection(FirebaseConfig.Collections.cats)
            .document(deviceID)
            .setData(["cats": json])
        
        print("✅ Cats saved successfully")
    }
    
    func loadCats() async throws -> [Cat] {
        let document = try await db.collection(FirebaseConfig.Collections.cats)
            .document(deviceID)
            .getDocument()
        
        guard let data = document.data(),
              let catsData = try? JSONSerialization.data(withJSONObject: data["cats"] ?? []),
              var cats = try? JSONDecoder().decode([Cat].self, from: catsData) else {
            return []
        }
        
        // 加载所有图片
        for i in cats.indices {
            if let urlString = cats[i].imageURL {
                cats[i].image = try await downloadImage(from: urlString)
            }
        }
        
        return cats
    }
    
    // 上传图片并返回URL
    private func uploadImage(_ image: UIImage, catId: UUID) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        
        let imagePath = "\(FirebaseConfig.StoragePaths.catImages)/\(deviceID)/\(catId.uuidString).jpg"
        let storageRef = storage.reference().child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL().absoluteString
    }
    
    // 从URL下载图片
    private func downloadImage(from urlString: String) async throws -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        let (data, _) = try await URLSession.shared.data(from: url)
        return UIImage(data: data)
    }
    
    // 修改获取品种图片的方法
    func fetchBreedImage(breed: String) async throws -> (url: String, image: UIImage)? {
        // 1. 对品种名进行 URL 编码
        guard let encodedBreed = breed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("❌ Failed to encode breed name")
            return nil
        }
        
        // 2. 获取品种信息
        let breedSearchUrl = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(encodedBreed)")!
        var request = URLRequest(url: breedSearchUrl)
        request.setValue("live_Gg8qZBEQZXvGYRyGZFXZzXkGEkxQGpVQIpWLlGXgOLgGRjmIrYgQF5wXWHhBzwbH", forHTTPHeaderField: "x-api-key")
        
        let (breedData, _) = try await URLSession.shared.data(from: request.url!)
        print("🔍 Breed search response: \(String(data: breedData, encoding: .utf8) ?? "")")
        
        guard let breeds = try? JSONDecoder().decode([BreedInfo].self, from: breedData),
              let breedInfo = breeds.first,
              let referenceImageId = breedInfo.reference_image_id else {
            print("❌ No breed info found for: \(breed)")
            return nil
        }
        
        // 3. 获取图片 URL
        let imageUrl = URL(string: "https://api.thecatapi.com/v1/images/\(referenceImageId)")!
        request = URLRequest(url: imageUrl)
        request.setValue("live_Gg8qZBEQZXvGYRyGZFXZzXkGEkxQGpVQIpWLlGXgOLgGRjmIrYgQF5wXWHhBzwbH", forHTTPHeaderField: "x-api-key")
        
        let (imageData, _) = try await URLSession.shared.data(from: request.url!)
        print("🖼 Image info response: \(String(data: imageData, encoding: .utf8) ?? "")")
        
        guard let catImage = try? JSONDecoder().decode(CatImage.self, from: imageData) else {
            print("❌ Failed to decode image info")
            return nil
        }
        
        // 4. 下载实际图片
        guard let finalImageUrl = URL(string: catImage.url),
              let (finalImageData, _) = try? await URLSession.shared.data(from: finalImageUrl),
              let image = UIImage(data: finalImageData) else {
            print("❌ Failed to download image from URL: \(catImage.url)")
            return nil
        }
        
        print("✅ Successfully got image for breed: \(breed)")
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
    
    // 保存 Wellness 数据
    func saveWellnessData(catId: UUID, diseases: [String]) async {
        do {
            try await db.collection(FirebaseConfig.Collections.cats)
                .document(deviceID)
                .collection("wellness")
                .document(catId.uuidString)
                .setData(["diseases": diseases])
        } catch {
            print("❌ Error saving wellness data: \(error)")
        }
    }
    
    // 保存事件
    func saveEvent(_ event: Event, forCat catId: String) async throws {
        let data = try JSONEncoder().encode(event)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { 
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode event"])
        }
        
        try await db.collection(FirebaseConfig.Collections.events)
            .document(catId)
            .collection("cat_events")
            .document(event.id.uuidString)
            .setData(json)
    }
    
    // 加载事件
    func loadEvents(forCat catId: String) async throws -> [Event] {
        print("📥 Loading events for cat: \(catId)")
        
        let eventsSnapshot = try await db.collection(FirebaseConfig.Collections.events)
            .document(catId)
            .collection("cat_events")
            .getDocuments()
        
        let events = try eventsSnapshot.documents.compactMap { document -> Event? in
            do {
                let data = try JSONSerialization.data(withJSONObject: document.data())
                let event = try JSONDecoder().decode(Event.self, from: data)
                return event
            } catch {
                print("⚠️ Failed to decode event from document: \(document.documentID)")
                print("Error: \(error)")
                print("Document data: \(document.data())")
                return nil
            }
        }
        
        print("✅ Loaded \(events.count) events")
        return events.sorted { $0.date < $1.date }
    }
    
    // 删除事件
    func deleteEvent(_ event: Event, forCat catId: String) async throws {
        print("📝 Deleting event from Firebase")
        print("Event ID: \(event.id)")
        print("Cat ID: \(catId)")
        print("Path: events/\(catId)/cat_events/\(event.id.uuidString)")
        
        try await db.collection(FirebaseConfig.Collections.events)
            .document(catId)
            .collection("cat_events")
            .document(event.id.uuidString)
            .delete()
        
        print("✅ Firebase delete operation completed")
    }
    
    func observeEvents(forCat catId: String, onChange: @escaping ([Event]) -> Void) -> ListenerRegistration {
        return db.collection(FirebaseConfig.Collections.events)
            .document(catId)
            .collection("cat_events")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let events = documents.compactMap { document -> Event? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data())
                        return try JSONDecoder().decode(Event.self, from: data)
                    } catch {
                        print("⚠️ Failed to decode event: \(error)")
                        return nil
                    }
                }
                
                onChange(events.sorted { $0.date < $1.date })
            }
    }
    
    // 删除猫咪的所有事件
    func deleteAllEvents(forCat catId: String) async throws {
        let eventsSnapshot = try await db.collection(FirebaseConfig.Collections.events)
            .document(catId)
            .collection("cat_events")
            .getDocuments()
        
        for document in eventsSnapshot.documents {
            try await db.collection(FirebaseConfig.Collections.events)
                .document(catId)
                .collection("cat_events")
                .document(document.documentID)
                .delete()
        }
    }
    
    func fetchHealthAnalyses(forCat catId: UUID) async throws -> [HealthAnalysis] {
        let snapshot = try await db.collection(FirebaseConfig.Collections.healthAnalyses)
            .whereField("catId", isEqualTo: catId.uuidString)
            .order(by: "date", descending: true)
            .limit(to: 5)  // 只获取最新的5条记录
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var data = document.data()
            
            // 将 Timestamp 转换回 Date
            if let timestamp = data["date"] as? Timestamp {
                data["date"] = Int(timestamp.dateValue().timeIntervalSince1970)
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(HealthAnalysis.self, from: jsonData)
        }
    }
    
    func saveHealthAnalysis(_ analysis: HealthAnalysis) async throws {
        // 先检查现有记录数量
        let snapshot = try await db.collection(FirebaseConfig.Collections.healthAnalyses)
            .whereField("catId", isEqualTo: analysis.catId.uuidString)
            .order(by: "date", descending: true)
            .getDocuments()
        
        // 如果已有5条或更多记录，删除最旧的记录
        if snapshot.documents.count >= 5 {
            let oldestDocs = snapshot.documents.suffix(from: 4)  // 从第5条开始的所有记录
            for doc in oldestDocs {
                try await doc.reference.delete()
            }
        }
        
        // 保存新记录
        let data = try JSONEncoder().encode(analysis)
        guard var dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert analysis to dictionary"])
        }
        
        // 将 Date 转换为 Timestamp
        if let dateDouble = dictionary["date"] as? Double {
            dictionary["date"] = Timestamp(date: Date(timeIntervalSince1970: dateDouble))
        }
        
        print("Attempting to save to Firebase:", dictionary)
        
        try await db.collection(FirebaseConfig.Collections.healthAnalyses)
            .document(analysis.id.uuidString)
            .setData(dictionary)
        
        print("Successfully saved to Firebase")
    }
    
    func deleteAllHealthAnalyses(forCat catId: UUID) async throws {
        let snapshot = try await db.collection(FirebaseConfig.Collections.healthAnalyses)
            .whereField("catId", isEqualTo: catId.uuidString)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func listenToHealthAnalyses(forCat catId: UUID, onChange: @escaping ([HealthAnalysis]) -> Void) async throws {
        db.collection(FirebaseConfig.Collections.healthAnalyses)
            .whereField("catId", isEqualTo: catId.uuidString)
            .order(by: "date", descending: true)
            .limit(to: 5)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("❌ Error fetching analyses:", error ?? "Unknown error")
                    return
                }
                
                let analyses = snapshot.documents.compactMap { document -> HealthAnalysis? in
                    var data = document.data()
                    
                    // 将 Timestamp 转换回 Date
                    if let timestamp = data["date"] as? Timestamp {
                        data["date"] = Int(timestamp.dateValue().timeIntervalSince1970)
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        return try JSONDecoder().decode(HealthAnalysis.self, from: jsonData)
                    } catch {
                        print("❌ Failed to decode analysis:", error)
                        return nil
                    }
                }
                
                onChange(analyses)
            }
    }
} 
