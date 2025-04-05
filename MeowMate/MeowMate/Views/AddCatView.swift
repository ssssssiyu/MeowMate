import SwiftUI

struct AddCatView: View {
    @Environment(\.dismiss) var dismiss
    let onCreate: (Cat) -> Void
    
    @State private var name: String = ""
    @State private var breed: String = ""
    @State private var birthDate = Date()
    @State private var gender: Cat.Gender = .male
    @State private var weight: String = ""
    @State private var isNeutered: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cat Information")) {
                    TextField("Name", text: $name)
                    TextField("Breed", text: $breed)
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag(Cat.Gender.male)
                        Text("Female").tag(Cat.Gender.female)
                    }
                    TextField("Weight", text: $weight)
                }
                
                Section(header: Text("Health Status")) {
                    Toggle("Neutered", isOn: $isNeutered)
                }
                
                Section(header: Text("Image")) {
                    Button("Select Image") {
                        showingImagePicker = true
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .navigationTitle("Add Cat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let weightValue = Double(weight) {
                            let weightRecord = WeightRecord(
                                id: UUID(),
                                date: Date(),
                                weight: weightValue
                            )
                            let newCat = Cat(
                                id: UUID(),
                                name: name,
                                breed: breed,
                                birthDate: birthDate,
                                gender: gender,
                                weightHistory: [weightRecord],
                                isNeutered: isNeutered,
                                image: selectedImage
                            )
                            onCreate(newCat)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || breed.isEmpty || weight.isEmpty)
                }
            }
        }
    }
} 