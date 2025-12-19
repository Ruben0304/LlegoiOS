import Foundation
import SwiftUI
import Combine

enum FavoritesViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var state: FavoritesViewState = .idle
    @Published var favoriteItems: [FavoriteItem] = []
    @Published var errorMessage: String?

    private let repository = FavoritesRepository()
    private let favoritesManager = FavoritesManager.shared
    private let cartManager = CartManager.shared

    func loadFavorites() {
        state = .loading
        errorMessage = nil

        repository.fetchFavoriteProducts { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let favoriteProducts):
                    self.favoriteItems = favoriteProducts.map { product in
                        FavoriteItem(
                            id: product.id,
                            name: product.name,
                            shop: "Store",
                            weight: product.weight,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.image,
                            availability: product.availability
                        )
                    }
                    self.state = .success

                case .failure(let error):
                    self.errorMessage = "Error al cargar favoritos: \(error.localizedDescription)"
                    self.state = .error(self.errorMessage ?? "Error desconocido")
                }
            }
        }
    }

    func removeFavorite(productId: String) {
        favoritesManager.removeFavorite(productId: productId)
    }

    func addToCart(productId: String) {
        cartManager.addToCart(productId: productId, quantity: 1)
    }
}

struct FavoriteItem: Identifiable, Hashable {
    let id: String
    let name: String
    let shop: String
    let weight: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool

    var formattedPrice: String {
        let symbol = currencySymbol(for: currency)
        return String(format: "%@%.2f", symbol, price)
    }

    private func currencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "CUP": return "$"
        default: return "$"
        }
    }
}
