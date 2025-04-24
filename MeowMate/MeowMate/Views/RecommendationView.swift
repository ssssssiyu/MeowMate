import SwiftUI

struct RecommendationView: View {
    @ObservedObject var viewModel: RecommendationViewModel
    
    var body: some View {
        VStack {
            if !viewModel.displayedProducts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.displayedProducts) { product in
                            Link(destination: URL(string: product.link) ?? URL(string: "https://www.petsmart.com")!) {
                                ProductCard(product: product)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .frame(height: 80)
            } else {
                Text("No products found")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

struct ProductCard: View {
    let product: PetFoodProduct
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(product.name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 160)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    RecommendationView(viewModel: RecommendationViewModel())
}

