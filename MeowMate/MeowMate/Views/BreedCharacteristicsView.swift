import SwiftUI

struct BreedCharacteristicsView: View {
    let breed: String
    @State private var breedInfo: BreedInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    struct BreedInfo: Codable {
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
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                ProgressView()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.secondary)
            } else if let info = breedInfo {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        CharacteristicRow(title: "Adaptability", value: info.adaptability)
                        CharacteristicRow(title: "Affection", value: info.affection_level)
                        CharacteristicRow(title: "Child Friendly", value: info.child_friendly)
                        CharacteristicRow(title: "Energy Level", value: info.energy_level)
                        CharacteristicRow(title: "Grooming", value: info.grooming)
                        CharacteristicRow(title: "Health Issues", value: info.health_issues)
                        CharacteristicRow(title: "Intelligence", value: info.intelligence)
                        CharacteristicRow(title: "Shedding Level", value: info.shedding_level)
                        CharacteristicRow(title: "Social Needs", value: info.social_needs)
                        CharacteristicRow(title: "Stranger Friendly", value: info.stranger_friendly)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                Text("No breed characteristics available")
                    .foregroundColor(.secondary)
            }
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
                        errorMessage = "No breed characteristics found"
                    }
                } catch {
                    errorMessage = "Failed to decode: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
} 