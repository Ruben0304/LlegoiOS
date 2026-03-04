import Combine
import Foundation
import SwiftUI

// MARK: - View State
enum ProductDetailState {
    case idle
    case loading
    case success(ProductDetailGraphQL)
    case error(String)
}

// MARK: - ProductDetailViewModel
@MainActor
class ProductDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: ProductDetailState = .idle
    @Published var productDetail: ProductDetailGraphQL?
    @Published var similarProducts: [Product] = []
    @Published var isLoadingSimilarProducts: Bool = false
    @Published var selectedByListId: [String: VariantOption] = [:]

    // MARK: - Private Properties
    private var loadedProductId: String?
    private var loadedSimilarQuery: String?

    // MARK: - Computed Properties
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }

    // MARK: - Dependencies
    private let repository = ProductDetailRepository()

    // MARK: - Public Methods
    func loadProductDetail(id: String, forceRefresh: Bool = false) {
        // Evitar cargas duplicadas del mismo producto
        guard forceRefresh || loadedProductId != id else {
            return
        }

        loadedProductId = id
        loadedSimilarQuery = nil
        similarProducts = []
        isLoadingSimilarProducts = false
        state = .loading

        repository.fetchProductDetail(id: id) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let detail):
                    self.productDetail = detail
                    self.initializeDefaultVariantSelection(from: detail)
                    self.state = .success(detail)
                    print("✅ ProductDetailViewModel: Loaded details for product \(id)")
                    
                    let cachedProduct = CachedProduct(
                        id: detail.id,
                        name: detail.name,
                        branchId: detail.branchId,
                        categoryId: detail.categoryId,
                        price: detail.price,
                        currency: detail.currency,
                        imageUrl: detail.imageUrl,
                        timestamp: Date(),
                        source: .viewed
                    )
                    ProductCacheManager.shared.addProduct(cachedProduct)
                    
                    self.loadSimilarProducts(using: detail.name, excludingProductId: id)

                case .failure(let error):
                    let message = "Error al cargar detalles: \(error.localizedDescription)"
                    self.state = .error(message)
                    self.loadedProductId = nil
                    print("❌ ProductDetailViewModel: \(message)")
                }
            }
        }
    }

    func loadSimilarProducts(
        using queryText: String, excludingProductId: String, forceRefresh: Bool = false
    ) {
        guard forceRefresh || loadedSimilarQuery != excludingProductId else {
            return
        }

        loadedSimilarQuery = excludingProductId
        isLoadingSimilarProducts = true

        repository.fetchSimilarProducts(productName: queryText, excludingProductId: excludingProductId) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoadingSimilarProducts = false
                switch result {
                case .success(let products):
                    self.similarProducts = Array(products.prefix(6))
                    print("✅ [ProductDetailViewModel] \(self.similarProducts.count) similares")
                case .failure:
                    self.similarProducts = []
                }
            }
        }
    }

    // MARK: - Helper Methods
    private func initializeDefaultVariantSelection(from detail: ProductDetailGraphQL) {
        var defaults: [String: VariantOption] = [:]
        
        guard let variantLists = detail.variantLists else {
            print("🧩 ProductDetailViewModel: No variant lists available for initialization")
            selectedByListId = defaults
            return
        }
        
        for list in variantLists {
            if let first = list.options.first {
                defaults[list.id] = first
            }
        }
        selectedByListId = defaults
        print(
            "🧩 ProductDetailViewModel: Default variant selections initialized for \(defaults.count) lists"
        )
    }

    func selectOption(_ option: VariantOption, in list: VariantList) {
        selectedByListId[list.id] = option
    }

    var selectedVariantOptions: [SelectedVariantOption] {
        guard let detail = productDetail,
              let variantLists = detail.variantLists else { return [] }
        return variantLists.compactMap { list in
            guard let selectedOption = selectedByListId[list.id] else { return nil }
            return SelectedVariantOption(
                listId: list.id,
                listName: list.name,
                optionId: selectedOption.id,
                optionName: selectedOption.name,
                priceAdjustment: selectedOption.priceAdjustment
            )
        }
    }

    func finalUnitPrice(for detail: ProductDetailGraphQL) -> Decimal {
        computeFinalUnitPrice(base: Decimal(detail.price), selected: selectedVariantOptions)
    }

    func finalTotalPrice(for detail: ProductDetailGraphQL, quantity: Int) -> Decimal {
        finalUnitPrice(for: detail) * Decimal(max(quantity, 1))
    }

    func formatPrice(decimal price: Decimal, currency: String) -> String {
        let number = NSDecimalNumber(decimal: price).doubleValue
        return formatPrice(price: number, currency: currency)
    }

    func formatPriceAdjustment(decimal price: Decimal, currency: String) -> String {
        if price == .zero {
            return formatPrice(decimal: price, currency: currency)
        }
        let sign = price > .zero ? "+" : ""
        return "\(sign)\(formatPrice(decimal: price, currency: currency))"
    }

    func formatPrice(price: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD":
            symbol = "$"
        case "EUR":
            symbol = "€"
        case "CUP":
            symbol = "CUP"
        default:
            symbol = currency
        }

        return String(format: "\(symbol) %.2f", price)
    }
}
