import SwiftUI
import PhotosUI

struct CatInfoFormView: View {
    let existingCat: Cat?
    let onSave: (Cat, UIImage?) -> Void
    private let formTitle: String  // 添加标题属性
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Cat"  // 默认名字设为 "Cat"
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

    // 添加最大日期限制
    private var maxDate: Date {
        Date()  // 当前日期作为最大值
    }

    init(existingCat: Cat? = nil, onSave: @escaping (Cat, UIImage?) -> Void) {
        self.existingCat = existingCat
        self.onSave = onSave
        self.formTitle = existingCat == nil ? "Add Cat Information" : "Edit Cat Information"
        
        if let cat = existingCat {
            _name = State(initialValue: cat.name)
            _birthDate = State(initialValue: cat.birthDate)
            _breed = State(initialValue: cat.breed)
            _gender = State(initialValue: cat.gender)
            _selectedImage = State(initialValue: cat.image)
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
        // 添加生日验证
        if birthDate > maxDate {
            validationMessage = "Birth date cannot be in the future"
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
            weightHistory: existingCat?.weightHistory ?? [],
            isNeutered: isNeutered,
            image: selectedImage ?? defaultImage,  // 使用选择的图片或默认图片
            imageURL: selectedImage == nil ? defaultImageURL : nil  // 如果使用默认图片，保存URL
        )
        
        // 如果是编辑现有猫咪
        if existingCat != nil {
            onSave(newCat, selectedImage ?? defaultImage)
            dismiss()
            return
        }
        
        // 如果是添加新猫咪
        onSave(newCat, selectedImage ?? defaultImage)
        dismiss()
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
                    DatePicker("Birth Date", 
                             selection: $birthDate,
                             in: ...maxDate,  // 添加日期范围限制
                             displayedComponents: .date)
                    Picker("Breed", selection: $breed) {
                        ForEach(breeds, id: \.self) { breed in
                            Text(breed).tag(breed)
                        }
                    }
                    .onAppear {
                        // 如果品种列表为空，设置一个默认值
                        if breeds.isEmpty {
                            breeds = ["Loading..."]
                        }
                    }
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag(Cat.Gender.male)
                        Text("Female").tag(Cat.Gender.female)
                    }
                    Toggle("Neutered", isOn: $isNeutered)  // 替换体重输入
                    
                    // 照片选择部分
                    VStack(alignment: .leading, spacing: 10) {
                        // 显示当前选择的图片预览
                        if let image = selectedImage ?? defaultImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // 分开的按钮组
                        VStack(spacing: 10) {
                            // 选择/更改照片按钮
                            Button(action: {
                                isPresentingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: selectedImage == nil ? "photo.badge.plus" : "photo")
                                    Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            // 使用默认照片按钮
                            Button(action: {
                                useDefaultImage()
                            }) {
                                HStack {
                                    if isLoadingDefaultImage {
                                        ProgressView()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "photo.circle.fill")
                                        Text("Use Default Photo")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isLoadingDefaultImage)
                        }
                    }
                }
            }
            .navigationTitle(formTitle)  // 使用动态标题
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
            .onChange(of: breed) { newBreed in
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
        if let defaultImage = defaultImage {
            selectedImage = nil  // 清除用户选择的图片
            // 不需要额外操作，因为视图会自动使用 defaultImage
        }
    }
} 
