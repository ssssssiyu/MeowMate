import SwiftUI

struct HomeView: View {
    @State private var isPresentingCatInfoForm = false
    @State private var cats: [Cat] = []
    @State private var selectedCatId: UUID?  // 改用 UUID 来追踪选中的猫咪
    @State private var isLoading = true  // 添加加载状态
    @State private var showingDeleteAlert = false  // 添加删除确认
    @State private var catToDeleteId: UUID?  // 改用 UUID 来追踪要删除的猫咪

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                } else if cats.isEmpty {
                    Text("No cats available. Please add a cat.")
                        .padding()
                } else {
                    TabView(selection: $selectedCatId) {
                        ForEach(cats, id: \.id) { cat in
                            CatDetailView(
                                cat: cat,
                                onDelete: {
                                    catToDeleteId = cat.id
                                    showingDeleteAlert = true
                                },
                                onUpdate: { updatedCat in
                                    if let index = cats.firstIndex(where: { $0.id == updatedCat.id }) {
                                        cats[index] = updatedCat
                                        Task {
                                            await saveData()
                                        }
                                    }
                                }
                            )
                            .tag(cat.id)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 55/255, green: 175/255, blue: 166/255))
                            .rotationEffect(.degrees(-15))
                            .offset(y: 2)
                        
                        Text("PawFile")
                            .font(.custom("Chalkboard SE", size: 24))
                            .foregroundColor(Color(red: 55/255, green: 175/255, blue: 166/255))
                            .shadow(color: Color(red: 55/255, green: 175/255, blue: 166/255).opacity(0.3), radius: 1, x: 1, y: 1)
                    }
                    .padding(.vertical, 4)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            isPresentingCatInfoForm = true
                        }) {
                            Text("Add Profile")
                        }
                        
                        if !cats.isEmpty {
                            Button(role: .destructive, action: {
                                if let currentCatId = selectedCatId {
                                    catToDeleteId = currentCatId
                                    showingDeleteAlert = true
                                }
                            }) {
                                Text("Delete Current Profile")
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 55/255, green: 175/255, blue: 166/255))
                    }
                }
            }
            .alert("Delete Profile", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { 
                    catToDeleteId = nil
                }
                Button("Delete", role: .destructive) {
                    if let id = catToDeleteId,
                       let index = cats.firstIndex(where: { $0.id == id }) {
                        deleteCat(at: index)
                    }
                    catToDeleteId = nil
                }
            } message: {
                if let id = catToDeleteId,
                   let cat = cats.first(where: { $0.id == id }) {
                    Text("Are you sure you want to delete \(cat.name)'s profile?")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingCatInfoForm) {
                CatInfoFormView(onSave: { newCat, image in
                    Task {
                        var catWithImage = newCat
                        catWithImage.image = image
                        
                        await MainActor.run {
                            cats.append(catWithImage)
                            selectedCatId = catWithImage.id
                        }
                        
                        // 保存到 UserDefaults
                        if let encodedData = try? JSONEncoder().encode(catWithImage) {
                            let key = "cat_\(catWithImage.id.uuidString)"
                            UserDefaults.standard.set(encodedData, forKey: key)
                        }
                    }
                })
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            // 加载数据
            await loadData()
        }
    }
    
    // 加载数据
    private func loadData() async {
        // 从 UserDefaults 加载猫咪数据
        let keys = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("cat_") }
        let loadedCats = keys.compactMap { key -> Cat? in
            guard let data = UserDefaults.standard.data(forKey: key),
                  let cat = try? JSONDecoder().decode(Cat.self, from: data) else {
                return nil
            }
            return cat
        }
        
        await MainActor.run {
            cats = loadedCats
            resetViewState()  // 重置视图状态
            isLoading = false
        }
    }
    
    // 保存数据
    private func saveData() async {
        // 保存每只猫咪到 UserDefaults
        for cat in cats {
            if let encodedData = try? JSONEncoder().encode(cat) {
                let key = "cat_\(cat.id.uuidString)"
                UserDefaults.standard.set(encodedData, forKey: key)
            }
        }
    }
    
    // 添加一个方法来重置视图状态
    private func resetViewState() {
        selectedCatId = cats.first?.id  // 选择第一只猫
    }
    
    // 修改删除方法
    private func deleteCat(at index: Int) {
        guard index < cats.count else { return }
        
        Task {
            let catToDelete = cats[index]
            
            await MainActor.run {
                cats.remove(at: index)
                resetViewState()
            }
            
            // 从 UserDefaults 中删除猫咪数据
            let key = "cat_\(catToDelete.id.uuidString)"
            UserDefaults.standard.removeObject(forKey: key)
            
            // 删除猫咪的事件数据
            let eventsKey = "events_\(catToDelete.id.uuidString)"
            UserDefaults.standard.removeObject(forKey: eventsKey)
            
            // 删除猫咪的健康分析数据
            let analysisKey = "analysis_history_\(catToDelete.id.uuidString)"
            UserDefaults.standard.removeObject(forKey: analysisKey)
        }
    }
}

