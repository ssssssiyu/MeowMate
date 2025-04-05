import SwiftUI

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 营养建议部分
            if !viewModel.recommendations.isEmpty {
                GeometryReader { geometry in
                    TabView {
                        ForEach(viewModel.recommendations) { recommendation in
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recommendation.title)
                                        .font(.system(size: 16, weight: .medium))
                                    Text(recommendation.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .frame(height: 45)
            }
            
            Divider()
            
            // 推荐产品部分
            if !viewModel.recommendedProducts.isEmpty {
                GeometryReader { geometry in
                    TabView {
                        ForEach(viewModel.recommendedProducts) { product in
                            Button(action: {
                                if let url = URL(string: product.link) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .lineLimit(2)
                                            .foregroundColor(.primary)
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                .frame(height: 55)
            }
        }
        .padding(.vertical, 4)
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

