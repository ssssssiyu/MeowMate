import SwiftUI
import PhotosUI

struct CatInfoFormView: View {
    let onSave: (Cat, UIImage?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Cat"  // 默认名字设为 "Cat"
    @State private var breed = "British Shorthair"  // 默认品种
    @State private var birthDate = Date()
    @State private var gender = Cat.Gender.female
    @State private var weight = ""
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var breeds: [String] = []
    @State private var isPresentingImagePicker = false
    @State private var isNeutered = false  // 添加在其他 @State 变量旁边
    
    private var existingWeightHistory: [WeightRecord]
    private let breedService = BreedService()
    @Environment(\.presentationMode) var presentationMode

    init(existingCat: Cat? = nil, onSave: @escaping (Cat, UIImage?) -> Void) {
        self.onSave = onSave
        self.existingWeightHistory = existingCat?.weightHistory ?? []
        
        if let cat = existingCat {
            _name = State(initialValue: cat.name)
            _birthDate = State(initialValue: cat.birthDate)
            _breed = State(initialValue: cat.breed)
            _gender = State(initialValue: cat.gender)
            _selectedImage = State(initialValue: cat.image)
        }
    }

    private var isFormValid: Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a name"
            return false
        }
        if breed.isEmpty {
            validationMessage = "Please select a breed"
            return false
        }
        if let weightValue = Double(weight) {
            if weightValue <= 0 {
                validationMessage = "Please enter a valid weight"
                return false
            }
        } else if !weight.isEmpty {
            validationMessage = "Please enter a valid weight"
            return false
        }
        return true
    }

    private func saveCat() {
        print("Attempting to save cat")
        let weightDouble = Double(weight) ?? 0
        
        let newCat = Cat(
            id: UUID(),
            name: name,
            breed: breed,
            birthDate: birthDate,
            gender: gender,
            weight: weightDouble,
            weightHistory: [
                WeightRecord(
                    id: UUID(),
                    date: Date(),
                    weight: weightDouble
                )
            ],
            isNeutered: isNeutered,
            image: selectedImage
        )
        
        // 如果用户选择了照片，直接使用
        if let selectedImage = selectedImage {
            print("Using selected image")
            onSave(newCat, selectedImage)
            dismiss()
            return
        }
        
        // 如果没有选择照片，从 API 获取
        Task {
            do {
                // 1. 先获取品种信息
                let breedSearchUrl = URL(string: "https://api.thecatapi.com/v1/breeds/search?q=\(breed)")!
                let (breedData, _) = try await URLSession.shared.data(from: breedSearchUrl)
                print("Breed Search Response: \(String(data: breedData, encoding: .utf8) ?? "no data")")
                
                guard let breeds = try? JSONDecoder().decode([BreedInfo].self, from: breedData),
                      let breedInfo = breeds.first,
                      let referenceImageId = breedInfo.reference_image_id else {
                    print("Could not find breed info for: \(breed)")
                    await MainActor.run {
                        onSave(newCat, nil)
                        dismiss()
                    }
                    return
                }
                
                // 2. 用参考图片 ID 获取具体图片
                let imageUrl = URL(string: "https://api.thecatapi.com/v1/images/\(referenceImageId)")!
                let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                print("Image Response: \(String(data: imageData, encoding: .utf8) ?? "no data")")
                
                guard let catImage = try? JSONDecoder().decode(CatImage.self, from: imageData),
                      let finalImageUrl = URL(string: catImage.url) else {
                    print("Could not get image URL")
                    await MainActor.run {
                        onSave(newCat, nil)
                        dismiss()
                    }
                    return
                }
                
                // 3. 下载实际图片
                let (finalImageData, _) = try await URLSession.shared.data(from: finalImageUrl)
                if let image = UIImage(data: finalImageData) {
                    print("Successfully got image")
                    await MainActor.run {
                        onSave(newCat, image)
                        dismiss()
                    }
                } else {
                    print("Could not create UIImage from data")
                    await MainActor.run {
                        onSave(newCat, nil)
                        dismiss()
                    }
                }
            } catch {
                print("Error fetching cat image: \(error)")
                await MainActor.run {
                    onSave(newCat, nil)
                    dismiss()
                }
            }
        }
    }

    // 添加这个结构体来解析 API 返回的 JSON
    private struct CatImage: Codable {
        let url: String
    }

    private struct BreedInfo: Codable {
        let id: String
        let name: String
        let reference_image_id: String?
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cat Information")) {
                    TextField("Name", text: $name)
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                    Picker("Breed", selection: $breed) {
                        Text("Select Breed").tag("")
                        ForEach(breeds, id: \.self) { breed in
                            Text(breed).tag(breed)
                        }
                    }
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag(Cat.Gender.male)
                        Text("Female").tag(Cat.Gender.female)
                    }
                    Toggle("Neutered", isOn: $isNeutered)  // 替换体重输入
                    Button(action: {
                        isPresentingImagePicker = true
                    }) {
                        Text(selectedImage == nil ? "Add Photo (Optional)" : "Change Photo")
                    }
                }
            }
            .navigationTitle("Add Cat Information")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if isFormValid {
                        saveCat()
                    } else {
                        showingValidationAlert = true
                    }
                }
            )
            .onAppear {
                breedService.fetchBreeds { fetchedBreeds in
                    self.breeds = fetchedBreeds
                }
            }
            .sheet(isPresented: $isPresentingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert(isPresented: $showingValidationAlert) {
                Alert(
                    title: Text("Invalid Form"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
} 
