import SwiftUI

struct CatDetailView: View {
    let cat: Cat
    let onDelete: () -> Void
    let onUpdate: (Cat) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Section
                Section {
                    HStack(alignment: .top, spacing: 20) {
                        // Left side - Information
                        VStack(alignment: .leading, spacing: 12) {
                            Text(cat.name)
                                .font(.title3)
                            Text(cat.breed)
                            Text("\(Calendar.current.dateComponents([.year], from: cat.birthDate, to: Date()).year ?? 0) years")
                            Text(cat.gender.rawValue)
                        }
                        
                        Spacer()
                        
                        // Right side - Photo
                        if let image = cat.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                
                // Weight Tracking Section
                Section {
                    Text("Weight History")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    WeightChartView(records: cat.weightHistory)
                        .frame(height: 300)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
            }
            .padding()
        }
        .navigationTitle(cat.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit", action: {
                        // TODO: Implement edit functionality
                    })
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CatDetailView(
            cat: Cat(
                name: "Luna",
                breed: "British Shorthair",
                birthDate: Date(),
                gender: .female,
                weight: 4.6,
                weightHistory: [
                    WeightRecord(date: Date().addingTimeInterval(-7*24*3600), weight: 4.2),
                    WeightRecord(date: Date().addingTimeInterval(-3*24*3600), weight: 4.5),
                    WeightRecord(date: Date(), weight: 4.6)
                ],
                image: nil
            ),
            onDelete: {},
            onUpdate: { _ in }
        )
    }
} 