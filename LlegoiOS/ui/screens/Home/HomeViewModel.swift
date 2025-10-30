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
    @Published var tutorials: [Tutorial] = []
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
                            id: productGraphQL.id, // Use real GraphQL ID
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

                    // Load mock tutorials
                    self.loadTutorials()

                    self.state = .success
                    print("✅ HomeViewModel: Loaded \(self.products.count) products, \(self.stores.count) stores, and \(self.tutorials.count) tutorials")

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

    private func loadTutorials() {
        // Mock tutorials data - En producción esto vendría de GraphQL
        let baseThumbnailUrl = "https://bucket-production-435ad.up.railway.app/tutoriales/Captura de pantalla 2025-10-30 a la(s) 12.17.10 p.m..png"

        tutorials = [
            Tutorial(
                id: "1",
                title: "Cómo hacer tu primer pedido",
                description: "Aprende a navegar por la app y realizar tu primera compra de manera fácil y rápida.",
                duration: "3:45",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Primeros pasos"
            ),
            Tutorial(
                id: "2",
                title: "Tips para ahorrar en tus compras",
                description: "Descubre cómo aprovechar las promociones y ofertas especiales de Llego.",
                duration: "5:12",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Consejos"
            ),
            Tutorial(
                id: "3",
                title: "Rastrea tu pedido en tiempo real",
                description: "Conoce todas las funciones del seguimiento de pedidos en vivo.",
                duration: "4:30",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Funciones avanzadas"
            ),
            Tutorial(
                id: "4",
                title: "Métodos de pago disponibles",
                description: "Conoce todas las formas de pago que puedes usar en Llego.",
                duration: "3:20",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Pagos"
            )
        ]
    }
}
