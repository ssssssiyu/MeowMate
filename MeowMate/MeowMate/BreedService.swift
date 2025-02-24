import Foundation

class BreedService {
    private let apiKey = "live_1jaydmAeXpGa3rl4Urjd1w8UuevfLp2FGvSycWAR4uZ8gS6kjyvbNrahOhathATD"
    private let baseURL = "https://api.thecatapi.com/v1/breeds"

    func fetchBreeds(completion: @escaping ([String]) -> Void) {
        guard let url = URL(string: "\(baseURL)?api_key=\(apiKey)") else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                    let breeds = jsonResult?.compactMap { $0["name"] as? String } ?? []
                    DispatchQueue.main.async {
                        completion(breeds)
                    }
                } catch {
                    print("JSON解析失败: \(error)")
                    completion([])
                }
            } else {
                completion([])
            }
        }.resume()
    }
} 