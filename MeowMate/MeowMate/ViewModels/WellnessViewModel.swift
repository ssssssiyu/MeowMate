import Foundation

@MainActor
class WellnessViewModel: ObservableObject {
    let cat: Cat
    @Published var selectedDiseases: [String] = []
    @Published var healthTips: [String] = []
    @Published var diseases: [Disease] = []
    @Published var isLoading = false
    @Published var error: Error?
    
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
    
    let diseaseOptions: [String: (String) -> String] = [
        "Blood in Urine": { age in age == "Kitten" ? "Seek immediate veterinary care! More dangerous for kittens!" : "Ensure adequate water intake, monitor for 24 hours." },
        "Vomiting": { age in age == "Adult" ? "Reduce dry food, provide more water." : "Might be hairballs, try hairball treatment." },
        "Diarrhea": { _ in "Provide easily digestible food, monitor for 24 hours." }
    ]
    
    var catAge: String {
        let age = Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0
        return age < 1 ? "Kitten" : "Adult"
    }
    
    private let diseaseService = DiseaseService()
    
    init(cat: Cat) {
        self.cat = cat
    }
    
    func updateHealthTips() {
        healthTips = selectedDiseases.compactMap { diseaseOptions[$0]?(catAge) }
    }
    
    func loadDiseases() {
        isLoading = true
        
        Task { @MainActor in
            do {
                let fetchedDiseases = try await diseaseService.fetchDiseases()
                self.diseases = fetchedDiseases
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
} 