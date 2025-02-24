import SwiftUI

struct HomeView: View {
    @State private var isPresentingCatInfoForm = false
    @State private var cats: [Cat] = []
    @State private var selectedCatIndex: Int = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if cats.isEmpty {
                    Text("No cats available. Please add a cat.")
                        .padding()
                } else {
                    TabView(selection: $selectedCatIndex) {
                        ForEach(cats.indices, id: \.self) { index in
                            CatDetailView(
                                cat: cats[index],
                                onDelete: {
                                    cats.remove(at: index)
                                    if selectedCatIndex >= cats.count {
                                        selectedCatIndex = max(cats.count - 1, 0)
                                    }
                                },
                                onUpdate: { updatedCat in
                                    cats[index] = updatedCat
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PawFile")
                        .font(.title2)
                        .bold()
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
                                cats.remove(at: selectedCatIndex)
                                if selectedCatIndex >= cats.count {
                                    selectedCatIndex = max(cats.count - 1, 0)
                                }
                            }) {
                                Text("Delete Profile")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPresentingCatInfoForm) {
                CatInfoFormView(onSave: { newCat, image in
                    var catWithImage = newCat
                    catWithImage.image = image
                    cats.append(catWithImage)
                })
                .navigationTitle("Add Cat Information")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    HomeView()
}

// 示例数据
let exampleCat = Cat(
    id: UUID(),
    name: "Example Cat",
    breed: "Mixed",
    birthDate: Date(),
    gender: .male,
    weight: 4.5,
    weightHistory: [WeightRecord(id: UUID(), date: Date(), weight: 4.5)],
    isNeutered: false
)
