import SwiftUI
import PhotosUI

struct CatInfoFormView: View {
    let onSave: (Cat, UIImage?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Cat"
    @State private var breed = "British Shorthair"
    @State private var birthDate = Date()
    @State private var gender = Gender.female
    @State private var weight = ""
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    
    private let commonBreeds = [
        "British Shorthair",
        "American Shorthair",
        "Persian",
        "Ragdoll",
        "Siamese",
        "Maine Coon",
        "Scottish Fold"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                Section(header: Text("Profile")) {
                    HStack(alignment: .top, spacing: 20) {
                        // Left side - Information
                        VStack(alignment: .leading, spacing: 16) {
                            TextField("", text: $name, prompt: Text("Name"))
                                .textFieldStyle(.plain)
                            
                            Picker("Breed", selection: $breed) {
                                ForEach(commonBreeds, id: \.self) { breed in
                                    Text(breed).tag(breed)
                                }
                            }
                            
                            HStack {
                                DatePicker("", selection: $birthDate, displayedComponents: .date)
                                    .labelsHidden()
                                Text("Birth Date")
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Picker("", selection: $gender) {
                                    Text("Female").tag(Gender.female)
                                    Text("Male").tag(Gender.male)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        Spacer()
                        
                        // Right side - Photo
                        PhotosPicker(selection: $imageSelection) {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "photo.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Weight Tracking Section
                Section(header: Text("Weight Tracking")) {
                    TextField("", text: $weight, prompt: Text("Weight (kg)"))
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Cat Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarRole(.navigationStack)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Cat Information")
                        .font(.subheadline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCat()
                    }
                    .disabled(name.isEmpty || breed.isEmpty || weight.isEmpty)
                }
            }
        }
    }
    
    private func saveCat() {
        guard let weightDouble = Double(weight) else { return }
        
        let newCat = Cat(
            name: name,
            breed: breed,
            birthDate: birthDate,
            gender: gender,
            weight: weightDouble,
            weightHistory: [WeightRecord(date: Date(), weight: weightDouble)],
            image: nil
        )
        
        onSave(newCat, selectedImage)
        dismiss()
    }
}

#Preview {
    CatInfoFormView { _, _ in }
} 