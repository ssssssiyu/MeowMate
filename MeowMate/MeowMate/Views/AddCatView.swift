import SwiftUI
import PhotosUI

struct AddCatView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (Cat) -> Void
    
    @State private var name = ""
    @State private var breed = ""
    @State private var birthDate = Date()
    @State private var gender = Cat.Gender.male
    @State private var weight = ""
    @State private var isNeutered = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextField("Breed", text: $breed)
                    DatePicker(
                        "Birth Date",
                        selection: $birthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .onChange(of: birthDate) { oldValue, newValue in
                        if newValue > Date() {
                            birthDate = Date()
                        }
                    }
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag(Cat.Gender.male)
                        Text("Female").tag(Cat.Gender.female)
                    }
                    Toggle("Neutered", isOn: $isNeutered)
                }
                
                Section(header: Text("Weight")) {
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Photo")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
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
                                weight: weightValue,
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
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
} 