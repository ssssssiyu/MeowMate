import SwiftUI

struct FoodRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let price: Double
    let imageUrl: String
    let purchaseUrl: String
    let description: String
}

struct RecommendationView: View {
    @State private var recommendations: [FoodRecommendation] = [
        FoodRecommendation(
            name: "幼猫营养猫粮",
            brand: "皇家",
            price: 199.0,
            imageUrl: "royal_canin_kitten",
            purchaseUrl: "https://example.com/royal-canin-kitten",
            description: "专为4-12个月幼猫设计的营养配方"
        )
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(recommendations) { item in
                    RecommendationCard(item: item)
                }
            }
            .padding()
        }
        .navigationTitle("推荐猫粮")
    }
}

struct RecommendationCard: View {
    let item: FoodRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片
            Image(systemName: "photo") // 临时使用系统图标替代
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .cornerRadius(8)
            
            // 商品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text("¥\(String(format: "%.2f", item.price))")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Link(destination: URL(string: item.purchaseUrl) ?? URL(string: "https://example.com")!) {
                        Text("购买")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct RecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecommendationView()
        }
    }
} 