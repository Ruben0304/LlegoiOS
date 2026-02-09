import Foundation
import SwiftUI
import Combine

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
    private let searchRepository = SearchRepository()

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
                    self.state = .success(detail)
                    print("✅ ProductDetailViewModel: Loaded details for product \(id)")
                    self.loadSimilarProducts(using: detail.description, excludingProductId: id)

                case .failure(let error):
                    let message = "Error al cargar detalles: \(error.localizedDescription)"
                    self.state = .error(message)
                    self.loadedProductId = nil // Permitir reintentar
                    print("❌ ProductDetailViewModel: \(message)")
                }
            }
        }
    }

    func loadSimilarProducts(using queryText: String, excludingProductId: String, forceRefresh: Bool = false) {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            similarProducts = []
            isLoadingSimilarProducts = false
            return
        }

        guard forceRefresh || loadedSimilarQuery != query else {
            return
        }

        loadedSimilarQuery = query
        isLoadingSimilarProducts = true

        searchRepository.searchProducts(query: query, first: 12) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingSimilarProducts = false

                switch result {
                case .success(let products):
                    self.similarProducts = Array(
                        products
                            .filter { $0.id != excludingProductId }
                            .prefix(6)
                    )
                    print("✅ ProductDetailViewModel: Loaded \(self.similarProducts.count) similar products")

                case .failure(let error):
                    self.similarProducts = []
                    print("⚠️ ProductDetailViewModel: Failed loading similar products - \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Helper Methods
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
