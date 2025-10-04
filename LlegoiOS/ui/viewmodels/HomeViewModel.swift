import Foundation
import SwiftUI
import Combine

// MARK: - View State
enum HomeViewState {
    case idle
    case loading
    case success
    case error(String)
}

// MARK: - HomeViewModel
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: HomeViewState = .idle
    @Published var products: [Product] = []
    @Published var stores: [Store] = []
    @Published var errorMessage: String?

    // MARK: - Computed Properties
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    // MARK: - Dependencies
    private let repository = HomeRepository()

    // Default images for stores (since backend doesn't provide them)
    private let defaultLogoUrl = "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
    private let defaultBannerUrl = "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"

    // MARK: - Public Methods
    func loadHomeData() {
        state = .loading
        errorMessage = nil

        repository.fetchHomeData { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let homeData):
                    // Map GraphQL products to UI Product model
                    self.products = homeData.products.map { productGraphQL in
                        Product(
                            id: Int(productGraphQL.id.hashValue),
                            name: productGraphQL.name,
                            shop: "Store", // Will be updated when we link products to branches
                            weight: productGraphQL.weight,
                            price: self.formatPrice(price: productGraphQL.price, currency: productGraphQL.currency),
                            imageUrl: productGraphQL.image
                        )
                    }

                    // Map GraphQL branches to UI Store model
                    self.stores = homeData.branches.map { branchGraphQL in
                        Store(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: self.calculateETA(coordinates: branchGraphQL.coordinates),
                            logoUrl: self.defaultLogoUrl,
                            bannerUrl: self.defaultBannerUrl,
                            address: branchGraphQL.address,
                            rating: nil // Backend doesn't provide rating yet
                        )
                    }

                    self.state = .success
                    print("✅ HomeViewModel: Loaded \(self.products.count) products and \(self.stores.count) stores")

                case .failure(let error):
                    let message = "Error al cargar datos: \(error.localizedDescription)"
                    self.errorMessage = message
                    self.state = .error(message)
                    print("❌ HomeViewModel: \(message)")
                }
            }
        }
    }

    // MARK: - Private Helpers
    private func formatPrice(price: Double, currency: String) -> String {
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

    private func calculateETA(coordinates: CoordinatesGraphQL) -> Int {
        // TODO: Implement proper ETA calculation based on user's location
        // For now, return a random value between 15 and 45 minutes
        return Int.random(in: 15...45)
    }
}
