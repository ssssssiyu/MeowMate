import SwiftUI

struct ProductFilterView: View {
    @StateObject private var viewModel: ProductFilterViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(recommendation: RecommendationViewModel.Recommendation, products: [PetFoodProduct]) {
        _viewModel = StateObject(wrappedValue: ProductFilterViewModel(
            recommendation: recommendation,
            products: products
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 筛选选项
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        title: "Brand",
                        isSelected: viewModel.selectedFilter == .brand,
                        action: { viewModel.selectedFilter = .brand }
                    )
                    
                    FilterButton(
                        title: "Flavor",
                        isSelected: viewModel.selectedFilter == .flavor,
                        action: { viewModel.selectedFilter = .flavor }
                    )
                    
                    FilterButton(
                        title: "Life Stage",
                        isSelected: viewModel.selectedFilter == .lifeStage,
                        action: { viewModel.selectedFilter = .lifeStage }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // 筛选选项列表
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filterOptions, id: \.self) { option in
                        FilterOptionRow(
                            option: option,
                            isSelected: viewModel.selectedOptions.contains(option),
                            action: { viewModel.toggleOption(option) }
                        )
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    viewModel.resetFilters()
                }
                .foregroundColor(mintGreen)
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? mintGreen : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct FilterOptionRow: View {
    let option: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(mintGreen)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    ProductFilterView(
        recommendation: RecommendationViewModel.Recommendation(
            title: "Test",
            description: "Test",
            type: .food,
            priority: .high
        ),
        products: []
    )
} 