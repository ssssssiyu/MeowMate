import SwiftUI

struct BreedDescriptionView: View {
    let breed: String
    @State private var breedInfo: BreedInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    struct BreedInfo: Codable {
        let description: String
        let temperament: String
        let origin: String
        let life_span: String
        let adaptability: Int
        let affection_level: Int
        let child_friendly: Int
        let energy_level: Int
        let grooming: Int
        let health_issues: Int
        let intelligence: Int
        let shedding_level: Int
        let social_needs: Int
        let stranger_friendly: Int
    }
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                } else if let info = breedInfo {
                    // Description
                    Text(info.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Compact Info Layout
                    HStack(spacing: 16) {
                        // Origin
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Origin")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(info.origin)
                                .font(.caption)
                        }
                        
                        // Life Span
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Life Span")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(info.life_span) years")
                                .font(.caption)
                        }
                        
                        // Temperament
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temperament")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(info.temperament)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    Text("No breed information available")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 8)
        }
        .onAppear {
            loadBreedInfo()
        }
    }
    
    private func loadBreedInfo() {
        guard let url = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(breed.replacingOccurrences(of: " ", with: "_").lowercased())") else {
            errorMessage = "Invalid breed name"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to load: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let breeds = try JSONDecoder().decode([BreedInfo].self, from: data)
                    if let firstBreed = breeds.first {
                        breedInfo = firstBreed
                    } else {
                        errorMessage = "No breed information found"
                    }
                } catch {
                    errorMessage = "Failed to decode: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
} 