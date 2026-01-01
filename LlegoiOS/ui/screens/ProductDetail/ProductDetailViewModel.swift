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
    func loadProductDetail(id: String) {
        state = .loading

        repository.fetchProductDetail(id: id) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let detail):
                    self.productDetail = detail
                    self.state = .success(detail)
                    print("✅ ProductDetailViewModel: Loaded details for product \(id)")

                case .failure(let error):
                    let message = "Error al cargar detalles: \(error.localizedDescription)"
                    self.state = .error(message)
                    print("❌ ProductDetailViewModel: \(message)")
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

        return String(format: "\(symbol)%.2f", price)
    }
}
