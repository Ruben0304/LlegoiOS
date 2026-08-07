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
    @Published var similarBranches: [BranchGraphQL] = []
    @Published var isLoadingSimilarProducts: Bool = false
    @Published var selectedByListId: [String: VariantOption] = [:]

    /// True cuando el detalle mostrado viene de los datos descargados
    /// (sin conexión), no del backend.
    @Published var isOfflineData: Bool = false

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
        isOfflineData = false
        state = .loading

        // Sin red: no tiene sentido esperar el timeout de la query; si el producto
        // está descargado se muestra directamente desde la base local.
        if !NetworkMonitor.shared.isConnected, loadOfflineProductDetail(id: id) {
            return
        }

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
                    
                    self.loadSimilarProducts(productId: id)
                    self.loadSimilarBranchesForProduct(productId: id)

                case .failure(let error):
                    // Antes de dar error, intentar con los datos descargados.
                    if self.loadOfflineProductDetail(id: id) {
                        print("📴 ProductDetailViewModel: detalle de \(id) servido desde datos offline")
                        return
                    }
                    let message = "Error al cargar detalles: \(error.localizedDescription)"
                    self.state = .error(message)
                    self.loadedProductId = nil
                    print("❌ ProductDetailViewModel: \(message)")
                }
            }
        }
    }

    // MARK: - Offline

    /// Carga el detalle desde los datos sincronizados. Devuelve false si el
    /// producto no está descargado (el llamador decide mostrar el error).
    @discardableResult
    private func loadOfflineProductDetail(id: String) -> Bool {
        let offlineRepo = OfflineDetailRepository.shared
        guard let detail = offlineRepo.productDetail(id: id) else { return false }

        loadedProductId = id
        productDetail = detail
        initializeDefaultVariantSelection(from: detail)
        state = .success(detail)
        isOfflineData = true

        // Secciones relacionadas, también desde la base local
        loadedSimilarQuery = id
        isLoadingSimilarProducts = false
        similarProducts = offlineRepo.similarProducts(productId: id)
        similarBranches = offlineRepo.branchesForProduct(productId: id)

        return true
    }

    func loadSimilarProducts(productId: String, forceRefresh: Bool = false) {
        guard forceRefresh || loadedSimilarQuery != productId else { return }
        loadedSimilarQuery = productId
        isLoadingSimilarProducts = true

        repository.fetchSimilarProducts(productId: productId) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoadingSimilarProducts = false
                switch result {
                case .success(let products):
                    self.similarProducts = products
                    print("✅ [ProductDetailViewModel] \(self.similarProducts.count) productos similares (Qdrant)")
                case .failure:
                    self.similarProducts = []
                }
            }
        }
    }

    func loadSimilarBranchesForProduct(productId: String) {
        repository.fetchSimilarBranchesForProduct(productId: productId) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let branches):
                    self.similarBranches = branches
                    print("✅ [ProductDetailViewModel] \(self.similarBranches.count) tiendas similares (Qdrant)")
                case .failure:
                    self.similarBranches = []
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
