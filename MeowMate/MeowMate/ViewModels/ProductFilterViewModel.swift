import Foundation
import Combine

class ProductFilterViewModel: ObservableObject {
    private let allProducts: [PetFoodProduct]
    var onFilteredProductsChanged: (([PetFoodProduct]) -> Void)?
    
    @Published var selectedFilter: FilterType = .brand {
        didSet {
            // 当切换过滤类型时，更新当前显示的选项
            selectedOptions = selectedOptionsByType[selectedFilter] ?? []
            updateFilterOptions()
            // 保存当前选择的过滤类型
            saveFilterState()
        }
    }
    
    @Published var selectedOptionsByType: [FilterType: Set<String>] = [
        .brand: [],
        .flavor: [],
        .lifeStage: []
    ] {
        didSet {
            // 当任何过滤类型的选项发生变化时，更新过滤结果
            updateFilteredProducts()
        }
    }
    
    @Published var selectedOptions: Set<String> = []
    @Published var filterOptions: [String] = []
    @Published var filteredProducts: [PetFoodProduct] = [] {
        didSet {
            onFilteredProductsChanged?(filteredProducts)
        }
    }
    
    enum FilterType: String, Codable {
        case brand
        case flavor
        case lifeStage
    }
    
    init(products: [PetFoodProduct], onFilteredProductsChanged: (([PetFoodProduct]) -> Void)? = nil) {
        self.allProducts = products
        self.onFilteredProductsChanged = onFilteredProductsChanged
        loadFilterState()
        updateFilterOptions()
        updateFilteredProducts()
    }
    
    private func saveFilterState() {
        let optionsByType = selectedOptionsByType.mapValues { Array($0) }
        let filterState = FilterState(
            selectedFilter: selectedFilter,
            selectedOptionsByType: optionsByType
        )
        if let encoded = try? JSONEncoder().encode(filterState) {
            UserDefaults.standard.set(encoded, forKey: "ProductFilterState")
        }
    }
    
    private func loadFilterState() {
        // 检查是否是第一次启动
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if isFirstLaunch {
            // 第一次启动，使用默认值
            selectedFilter = .brand
            selectedOptionsByType = [
                .brand: [],
                .flavor: [],
                .lifeStage: []
            ]
            selectedOptions = []
            
            // 标记已经启动过
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        } else if let data = UserDefaults.standard.data(forKey: "ProductFilterState"),
                  let filterState = try? JSONDecoder().decode(FilterState.self, from: data) {
            // 非第一次启动，加载保存的状态
            selectedFilter = filterState.selectedFilter
            selectedOptionsByType = filterState.selectedOptionsByType.mapValues { Set($0) }
            selectedOptions = selectedOptionsByType[selectedFilter] ?? []
        }
    }
    
    private struct FilterState: Codable {
        let selectedFilter: FilterType
        let selectedOptionsByType: [FilterType: [String]]
    }
    
    func toggleOption(_ option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
            selectedOptionsByType[selectedFilter]?.remove(option)
            
            // 如果当前类型没有选中的选项，更新过滤结果
            if selectedOptionsByType[selectedFilter]?.isEmpty == true {
                // 检查其他类型是否有选中的选项
                let hasOtherFilters = selectedOptionsByType.contains { (key, value) in
                    key != selectedFilter && !value.isEmpty
                }
                
                if !hasOtherFilters {
                    // 如果没有其他过滤器，重置为显示所有产品
                    filteredProducts = allProducts
                    onFilteredProductsChanged?(allProducts)
                } else {
                    // 如果有其他过滤器，重新应用过滤
                    updateFilteredProducts()
                }
            } else {
                updateFilteredProducts()
            }
        } else {
            selectedOptions.insert(option)
            selectedOptionsByType[selectedFilter]?.insert(option)
            updateFilteredProducts()
        }
        
        saveFilterState()
    }
    
    func resetFilters() {
        selectedOptionsByType = [
            .brand: [],
            .flavor: [],
            .lifeStage: []
        ]
        selectedOptions = []
        filteredProducts = allProducts
        onFilteredProductsChanged?(allProducts)
        saveFilterState()
    }
    
    private func formatDisplayText(_ text: String) -> String {
        let words = text.split(separator: " ")
        let formattedWords = words.map { word -> String in
            let lowercased = word.lowercased()
            let formatted = lowercased.prefix(1).uppercased() + lowercased.dropFirst()
            return formatted
        }
        return formattedWords.joined(separator: " ")
    }
    
    private func updateFilterOptions() {
        switch selectedFilter {
        case .brand:
            let brands = Set(allProducts.compactMap { $0.brand }.filter { $0 != "N/A" }).sorted()
            filterOptions = cleanBrandNames(brands).map { formatDisplayText($0) }
        case .flavor:
            let allFlavors = allProducts.compactMap { $0.flavor }
                .flatMap { extractFlavors($0) }
            filterOptions = Array(Set(allFlavors)).sorted().map { formatDisplayText($0) }
        case .lifeStage:
            // 提取所有生命阶段并标准化
            let stages = allProducts.map { product -> Set<String> in
                let stage = product.lifeStage
                return normalizeLifeStage(stage)
            }
            // 合并所有生命阶段并排序
            let uniqueStages = stages.reduce(into: Set<String>()) { result, stages in
                result.formUnion(stages)
            }
            // 过滤掉 "All" 相关的选项，因为它们不应该出现在过滤选项中
            filterOptions = Array(uniqueStages)
                .filter { !$0.lowercased().contains("all") }
                .sorted()
        }
    }
    
    private func normalizeLifeStage(_ stage: String) -> Set<String> {
        let lowercased = stage.lowercased()
        var stages = Set<String>()
        
        // 处理基本生命阶段，忽略 indoor 属性
        if lowercased.contains("kitten") {
            stages.insert("Kitten")
        }
        if lowercased.contains("adult") {
            stages.insert("Adult")
        }
        if lowercased.contains("senior") || lowercased.contains("7+") || lowercased.contains("11+") {
            stages.insert("Senior")
        }
        
        return stages
    }
    
    private func updateFilteredProducts() {
        // 检查是否有任何过滤条件被选中
        let hasAnyFilters = selectedOptionsByType.values.contains { !$0.isEmpty }
        
        if !hasAnyFilters {
            filteredProducts = allProducts
            onFilteredProductsChanged?(allProducts)
            return
        }
        
        // 应用过滤条件
        let filtered = allProducts.filter { product in
            var matches = true
            
            // 检查品牌过滤器
            if !selectedOptionsByType[.brand]!.isEmpty {
                if let brand = product.brand {
                    let normalizedBrand = normalizeBrandName(brand)
                    matches = matches && selectedOptionsByType[.brand]!.contains(formatDisplayText(normalizedBrand))
                } else {
                    matches = false
                }
            }
            
            // 检查口味过滤器
            if matches && !selectedOptionsByType[.flavor]!.isEmpty {
                if let flavor = product.flavor {
                    let productFlavors = Set(extractFlavors(flavor).map { formatDisplayText($0) })
                    matches = matches && !selectedOptionsByType[.flavor]!.isDisjoint(with: productFlavors)
                } else {
                    matches = false
                }
            }
            
            // 检查生命阶段过滤器
            if matches && !selectedOptionsByType[.lifeStage]!.isEmpty {
                let productStages = normalizeLifeStage(product.lifeStage)
                if !product.lifeStage.lowercased().contains("all") {
                    matches = matches && !selectedOptionsByType[.lifeStage]!.isDisjoint(with: productStages)
                }
            }
            
            return matches
        }
        
        filteredProducts = filtered
        onFilteredProductsChanged?(filtered)
        saveFilterState()
    }
    
    private func extractFlavors(_ flavor: String) -> [String] {
        let rawFlavor = flavor.uppercased()
        var flavors = Set<String>()
        
        // 口味映射规则
        let flavorMappings: [String: [String]] = [
            // 家禽类
            "CHICKEN": ["CHICKEN", "CAGE-FREE CHICKEN", "ROASTED CHICKEN", "GRILLED CHICKEN", "CHICKEN RECIPE", "CHICKEN FORMULA", "INDOOR CHICKEN", "CHICKEN INDOOR"],
            "TURKEY": ["TURKEY", "ROASTED TURKEY", "TURKEY RECIPE", "INDOOR TURKEY", "TURKEY INDOOR"],
            "DUCK": ["DUCK", "ROASTED DUCK", "DUCK RECIPE", "INDOOR DUCK", "DUCK INDOOR"],
            
            // 海洋类蛋白质
            "FISH & SEAFOOD": [
                // 鱼类
                "FISH", "OCEAN FISH", "SEAFOOD", "SEA FOOD", "INDOOR FISH", "FISH INDOOR",
                "WHITEFISH", "WHITE FISH", "OCEAN WHITEFISH",
                "SALMON", "WILD SALMON", "PACIFIC SALMON", "SALMON RECIPE", "INDOOR SALMON",
                "TUNA", "SKIPJACK TUNA", "TUNA RECIPE", "INDOOR TUNA",
                "HERRING", "MACKEREL", "TROUT",
                // 其他海鲜
                "SHRIMP", "PRAWNS", "CRAB", "CRAB MEAT",
                // 各种变体
                "INDOOR HERRING", "HIGH PROTEIN HERRING", "HERRING INDOOR",
                "INDOOR TROUT", "HEALTH TROUT", "INDOOR HEALTH TROUT",
                "INDOOR MACKEREL", "MACKEREL INDOOR"
            ],
            
            // 肉类
            "BEEF": ["BEEF", "BEEF RECIPE", "BEEF FORMULA", "INDOOR BEEF", "BEEF INDOOR"],
            "LAMB": ["LAMB", "LAMB RECIPE", "LAMB FORMULA", "INDOOR LAMB", "LAMB INDOOR"],
            
            // 内脏类
            "LIVER": ["LIVER", "CHICKEN LIVER", "BEEF LIVER"],
            
            // 主食配料
            "RICE": ["RICE", "BROWN RICE", "WHITE RICE"],
            "POTATO": ["POTATO", "POTATOES", "SWEET POTATO", "SWEETPOTATO"]
        ]
        
        // 要移除的修饰词
        let wordsToRemove = [
            "INDOOR", "OUTDOOR", "HEALTH", "HEALTHY", "NATURAL", "PREMIUM",
            "HIGH PROTEIN", "LOW FAT", "GRAIN FREE", "FORMULA", "RECIPE",
            "PATE", "CUTS", "SLICED", "MORSELS", "CHUNKS", "FLAKED",
            "CLASSIC", "GOURMET", "DELUXE", "SUPREME", "PRIME", "SPECIAL",
            "BLEND", "MIX", "FEAST", "DINNER", "ENTRÉE", "PLATTER",
            "ADULT", "KITTEN", "SENIOR", "MATURE", "ALL AGES",
            "WITH", "IN", "AND", "FOR", "CATS", "CAT"
        ]
        
        // 分割原始口味字符串并清理
        var components = rawFlavor.components(separatedBy: CharacterSet(charactersIn: "&,+"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // 移除修饰词
        components = components.map { component in
            var cleaned = component
            for word in wordsToRemove {
                cleaned = cleaned.replacingOccurrences(of: " \(word) ", with: " ")
                cleaned = cleaned.replacingOccurrences(of: " \(word)", with: "")
                cleaned = cleaned.replacingOccurrences(of: "\(word) ", with: "")
            }
            return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 处理每个部分
        for component in components {
            guard !component.isEmpty else { continue }
            
            // 检查是否匹配任何标准口味
            for (standardFlavor, variations) in flavorMappings {
                if variations.contains(where: { component.contains($0) }) {
                    flavors.insert(standardFlavor)
                    break
                }
            }
        }
        
        return Array(flavors)
    }
    
    private func cleanBrandNames(_ brands: [String]) -> [String] {
        var brandGroups: [String: Set<String>] = [:]
        
        for brand in brands {
            let normalizedName = normalizeBrandName(brand)
            brandGroups[normalizedName, default: []].insert(brand)
        }
        
        return Array(brandGroups.keys).sorted()
    }
    
    private func normalizeBrandName(_ brand: String) -> String {
        let uppercaseBrand = brand.uppercased()
        
        // 品牌规范化规则
        let brandMappings: [String: [String]] = [
            // 主流品牌
            "BLUE BUFFALO": ["BLUE", "BLUE FREEDOM", "BLUE WILDERNESS", "BLUE FOR CATS", "BLUE BASICS"],
            "ROYAL CANIN": ["ROYAL CANIN", "ROYALCANIN", "ROYAL"],
            "HILLS SCIENCE": ["HILLS", "HILL'S", "SCIENCE DIET", "HILLS SCIENCE", "SCIENCE PLAN"],
            "PURINA": ["PURINA", "PURINA ONE", "PURINA PRO", "PRO PLAN", "PURINA PRO PLAN"],
            "IAMS": ["IAMS", "IAMS PROACTIVE", "IAMS HEALTHY"],
            
            // 天然品牌
            "WELLNESS": ["WELLNESS", "WELLNESS CORE", "WELLNESS COMPLETE"],
            "NATURAL BALANCE": ["NATURAL BALANCE", "NAT BALANCE"],
            "NATURE'S VARIETY": ["NATURE'S VARIETY", "NATURES VARIETY", "INSTINCT"],
            "NULO": ["NULO", "NULO FREESTYLE", "NULO FRONTRUNNER", "NULO MEDALSERIES", "NULO MEDAL SERIES"],
            "NUTRIENCE": ["NUTRIENCE", "NUTRIENCE ORIGINAL", "NUTRIENCE INFUSION", "NUTRIENCE CARE"],
            "REVEAL": ["REVEAL", "REVEAL NATURAL", "REVEAL NATURAL DRY CAT FOOD", "REVEAL CAT", "REVEAL PET FOOD"],
            
            // 专业品牌
            "TIKI CAT": ["TIKI", "TIKI CAT", "TIKICAT"],
            "WERUVA": ["WERUVA", "WERUVA CATS"],
            "MERRICK": ["MERRICK", "MERRICK PURRFECT"],
            
            // 罐头品牌
            "FANCY FEAST": ["FANCY FEAST", "FANCYFEAST", "FANCY"],
            "SHEBA": ["SHEBA", "SHEBA PERFECT"],
            
            // 其他品牌
            "ORIJEN": ["ORIJEN", "ORIJEN CAT"],
            "ACANA": ["ACANA", "ACANA CAT"],
            "ZIWI PEAK": ["ZIWI", "ZIWI PEAK", "ZIWIPEAK"],
            "APPLAWS": ["APPLAWS", "APPLAWS CAT"],
            "AUTHORITY": ["AUTHORITY", "AUTHORITY CAT"],
            "BEYOND": ["BEYOND", "PURINA BEYOND"],
            "FRISKIES": ["FRISKIES", "FRISKIES CAT"],
            "HALO": ["HALO", "HALO CATS"],
            "NUTRO": ["NUTRO", "NUTRO CAT", "NUTRO NATURAL"]
        ]
        
        // 检查品牌是否需要规范化
        for (normalizedName, variations) in brandMappings {
            if variations.contains(where: { uppercaseBrand.contains($0) }) {
                return normalizedName
            }
        }
        
        return brand
    }
} 