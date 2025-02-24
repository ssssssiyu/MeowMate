import SwiftUI

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.recommendations) { recommendation in
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.callout)
                        .bold()
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                if !viewModel.recommendedProducts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.recommendedProducts) { product in
                                ProductCard(product: product)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        Link(destination: URL(string: product.url)!) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.caption)
                    .lineLimit(2)
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.caption)
                    .bold()
            }
            .frame(width: 120)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 