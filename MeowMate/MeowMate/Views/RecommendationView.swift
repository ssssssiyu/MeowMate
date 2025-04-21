import SwiftUI

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        if !viewModel.recommendedProducts.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.recommendedProducts) { product in
                        NavigationLink(destination: ProductFilterView(
                            recommendation: viewModel.recommendations.first ?? RecommendationViewModel.Recommendation(
                                title: "Pet Food",
                                description: "",
                                type: .food,
                                priority: .medium
                            ),
                            products: viewModel.recommendedProducts
                        )) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        } else {
            Text("No recommended products")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

// 推荐轮播组件
struct RecommendationsCarousel: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        GeometryReader { geometry in
            TabView {
                ForEach(viewModel.recommendations) { recommendation in
                    NavigationLink(destination: ProductFilterView(
                        recommendation: recommendation,
                        products: viewModel.getProductsForRecommendation(recommendation)
                    )) {
                        RecommendationCard(recommendation: recommendation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(height: 45)
    }
}

// 产品轮播组件
struct ProductsCarousel: View {
    let products: [PetFoodProduct]
    
    var body: some View {
        GeometryReader { geometry in
            TabView {
                ForEach(products) { product in
                    ProductCard(product: product)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .frame(height: 55)
    }
}

// 产品卡片组件
struct ProductCard: View {
    let product: PetFoodProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name)
                .font(.system(size: 16, weight: .medium))
                .lineLimit(2)
                .foregroundColor(.primary)
            
            Text(product.lifeStage)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("View Product")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .frame(width: 200)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// 标签视图
struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// 推荐卡片组件
struct RecommendationCard: View {
    let recommendation: RecommendationViewModel.Recommendation
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.system(size: 16, weight: .medium))
                Text(recommendation.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
    }
}

