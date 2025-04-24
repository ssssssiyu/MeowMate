import SwiftUI

struct ProductFilterView: View {
    @StateObject private var viewModel: ProductFilterViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(products: [PetFoodProduct], onFilteredProductsChanged: (([PetFoodProduct]) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: ProductFilterViewModel(
            products: products,
            onFilteredProductsChanged: onFilteredProductsChanged ?? { _ in }
        ))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 筛选选项
                HStack(spacing: 16) {
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
                .padding(.top, 28)
                
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
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
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
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? mintGreen : Color.white)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
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
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
            }
            .padding()
            .background(isSelected ? mintGreen : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
        }
    }
}
 