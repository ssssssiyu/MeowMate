import SwiftUI
import PhotosUI

struct CatInfoFormView: View {
    let existingCat: Cat?
    let onSave: (Cat, UIImage?) -> Void
    private let formTitle: String  // 添加标题属性
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""  // 默认名字设为 "Cat"
    @State private var breed = ""  // 改为空字符串作为初始值
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
    @State private var isLoadingDefaultImage = false  // 添加加载状态
    @State private var defaultImage: UIImage?  // 存储当前品种的默认图片
    @State private var defaultImageURL: String?  // 存储默认图片的URL
    
    private let breedService = BreedService()
    @Environment(\.presentationMode) var presentationMode

    init(existingCat: Cat? = nil, onSave: @escaping (Cat, UIImage?) -> Void) {
        self.existingCat = existingCat
        self.onSave = onSave
        self.formTitle = existingCat == nil ? "Add Cat Information" : "Edit Cat Information"
        
        if let cat = existingCat {
            _name = State(initialValue: cat.name)
            _birthDate = State(initialValue: cat.birthDate)
            _breed = State(initialValue: cat.breed)
            _gender = State(initialValue: cat.gender)
            _selectedImage = State(initialValue: cat.imageURL == nil ? cat.image : nil)  // 只有当不是默认图片时才设置selectedImage
            _isNeutered = State(initialValue: cat.isNeutered)
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
        
        let newCat = Cat(
            id: existingCat?.id ?? UUID(),
            name: name,
            breed: breed,
            birthDate: birthDate,
            gender: gender,
            weight: existingCat?.weight ?? 0,
            weightHistory: existingCat?.weightHistory ?? [],
            isNeutered: isNeutered,
            image: selectedImage ?? defaultImage,
            imageURL: selectedImage == nil ? defaultImageURL : nil
        )
        
        // 只保存到本地
        if let encodedData = try? JSONEncoder().encode(newCat) {
            let key = "cat_\(newCat.id.uuidString)"
            UserDefaults.standard.set(encodedData, forKey: key)
            
            // 更新猫咪列表
            var cats = loadCats()
            if let index = cats.firstIndex(where: { $0.id == newCat.id }) {
                cats[index] = newCat
            } else {
                cats.append(newCat)
            }
            saveCats(cats)
        }
        
        onSave(newCat, selectedImage ?? defaultImage)
        dismiss()
    }
    
    private func loadCats() -> [Cat] {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("cat_") }
        return keys.compactMap { key in
            guard let data = UserDefaults.standard.data(forKey: key),
                  let cat = try? JSONDecoder().decode(Cat.self, from: data) else {
                return nil
            }
            return cat
        }
    }
    
    private func saveCats(_ cats: [Cat]) {
        let catsData = cats.compactMap { cat -> Data? in
            try? JSONEncoder().encode(cat)
        }
        UserDefaults.standard.set(catsData, forKey: "cats")
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
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Cat Information Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        SectionHeader(title: "Cat Information", icon: "pawprint.circle.fill")
                        
                        VStack(spacing: Theme.Spacing.medium) {
                            HStack(spacing: Theme.Spacing.medium) {
                                CustomTextField(title: "Name", text: $name)
                                    .frame(maxWidth: .infinity)
                                CustomDatePicker(title: "Birth Date", date: $birthDate)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            CustomPicker(title: "Breed", selection: $breed, options: breeds)
                            
                            CustomGenderPicker(selection: $gender)
                            
                            Toggle("Neutered", isOn: $isNeutered)
                                .tint(Theme.mintGreen)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .shadow(radius: Theme.Shadow.light)
                    }
                    .padding(.horizontal)
                    
                    // Photo Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        SectionHeader(title: "Photo", icon: "photo.circle.fill")
                        
                        VStack(spacing: Theme.Spacing.medium) {
                            if let image = selectedImage ?? defaultImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                            }
                            
                            HStack(spacing: Theme.Spacing.small) {
                                Button(action: {
                                    isPresentingImagePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Select")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.mintGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.CornerRadius.small)
                                }
                                
                                Button(action: {
                                    useDefaultImage()
                                }) {
                                    HStack {
                                        if isLoadingDefaultImage {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "photo")
                                            Text("Default")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.mintGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(Theme.CornerRadius.small)
                                }
                                .disabled(isLoadingDefaultImage)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .shadow(radius: Theme.Shadow.light)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Theme.Text.navigationTitle(formTitle)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.mintGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if isFormValid {
                            saveCat()
                        } else {
                            showingValidationAlert = true
                        }
                    }
                    .foregroundColor(Theme.mintGreen)
                }
            }
            .sheet(isPresented: $isPresentingImagePicker) {
                ImagePicker(image: $selectedImage)
                    .onChange(of: selectedImage) { oldImage, newImage in
                        // 只有当用户真正选择了新图片时，才使用选择的图片
                        if newImage != nil {
                            defaultImage = nil
                            defaultImageURL = nil
                        }
                    }
            }
            .alert(isPresented: $showingValidationAlert) {
                Alert(
                    title: Text("Invalid Form"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // 加载品种列表
                breedService.fetchBreeds { fetchedBreeds in
                    self.breeds = fetchedBreeds
                    // 如果当前选择的品种不在列表中，选择第一个品种
                    if !fetchedBreeds.contains(breed) {
                        breed = fetchedBreeds.first ?? ""
                    }
                }
                
                // 初始加载默认图片
                loadDefaultImage(for: breed)
            }
            .onChange(of: breed) { oldBreed, newBreed in
                // 当品种改变时，加载新的默认图片
                loadDefaultImage(for: newBreed)
            }
        }
    }
    
    // 加载默认图片
    private func loadDefaultImage(for breed: String) {
        guard !breed.isEmpty else { return }
        
        Task {
            isLoadingDefaultImage = true
            if let breedImage = try? await DataService.shared.fetchBreedImage(breed: breed) {
                await MainActor.run {
                    defaultImage = breedImage.image
                    defaultImageURL = breedImage.url
                    // 如果用户没有选择自定义图片，则使用默认图片
                    if selectedImage == nil {
                        useDefaultImage()
                    }
                    isLoadingDefaultImage = false
                }
            } else {
                await MainActor.run {
                    defaultImage = nil
                    defaultImageURL = nil
                    isLoadingDefaultImage = false
                }
            }
        }
    }
    
    // 修改使用默认图片的方法
    private func useDefaultImage() {
        selectedImage = nil  // 清除用户选择的图片
    }
}

// 自定义组件
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.mintGreen)
            Text(title)
                .font(.headline)
                .bold()
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accentColor(Theme.mintGreen)
        }
    }
}

struct CustomDatePicker: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .accentColor(Theme.mintGreen)
        }
    }
}

struct CustomPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                    }) {
                        if selection == option {
                            Label(option, systemImage: "checkmark")
                        } else {
                            Text(option)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.isEmpty ? "Select a breed" : selection)
                        .foregroundColor(selection.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
    }
}

struct CustomGenderPicker: View {
    @Binding var selection: Cat.Gender
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Gender")
                .font(.subheadline)
                .foregroundColor(.gray)
            Picker("", selection: $selection) {
                Text("Male").tag(Cat.Gender.male)
                Text("Female").tag(Cat.Gender.female)
            }
            .pickerStyle(.segmented)
            .accentColor(Theme.mintGreen)
        }
    }
} 
