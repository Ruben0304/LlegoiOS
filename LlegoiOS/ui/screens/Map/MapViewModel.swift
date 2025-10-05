import Foundation
import SwiftUI
import MapKit
import Combine

enum MapViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class MapViewModel: ObservableObject {
    @Published var state: MapViewState = .idle
    @Published var stores: [Store] = []
    @Published var storeLocations: [String: CLLocationCoordinate2D] = [:]
    @Published var selectedCategory: String? = nil
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let repository = MapRepository()
    private var allStores: [Store] = []
    private var allStoreLocations: [String: CLLocationCoordinate2D] = [:]

    // Categorías disponibles (mismas que CategoriesView)
    let categories = [
        "Italiana",
        "Platos Fuertes",
        "Vegetariana",
        "Batidos y Cócteles",
        "Bebidas Enlatadas",
        "Botellas"
    ]

    func loadBranches() {
        state = .loading
        isLoading = true
        errorMessage = nil

        repository.fetchBranches { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let branchesGraphQL):
                    // Map to UI models and store coordinates
                    self.allStores = branchesGraphQL.compactMap { branchGraphQL in
                        guard let coordinate = self.coordinatesFromGraphQL(branchGraphQL.coordinates) else {
                            return nil
                        }

                        // Store coordinate mapping
                        self.allStoreLocations[branchGraphQL.id] = coordinate

                        return Store(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: self.calculateETA(coordinates: branchGraphQL.coordinates),
                            logoUrl: self.defaultLogoUrl,
                            bannerUrl: self.defaultBannerUrl,
                            address: branchGraphQL.address,
                            rating: nil
                        )
                    }

                    self.stores = self.allStores
                    self.storeLocations = self.allStoreLocations
                    self.state = .success
                    self.isLoading = false

                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.state = .error(self.errorMessage!)
                    self.isLoading = false
                }
            }
        }
    }

    func filterByCategory(_ category: String?) {
        selectedCategory = category

        if let category = category {
            // TODO: Implementar filtrado real cuando tengamos categorías en el backend
            // Por ahora, mostrar todas las tiendas
            stores = allStores
            storeLocations = allStoreLocations
            print("🔍 Filtering by category: \(category)")
        } else {
            stores = allStores
            storeLocations = allStoreLocations
        }
    }

    // MARK: - Helper functions

    private func calculateETA(coordinates: MapCoordinatesGraphQL) -> Int {
        // Por ahora, retornar un valor aleatorio entre 15-45 minutos
        // TODO: Calcular ETA real basado en la distancia del usuario
        return Int.random(in: 15...45)
    }

    private var defaultLogoUrl: String {
        "https://cdn-icons-png.flaticon.com/512/3081/3081559.png"
    }

    private var defaultBannerUrl: String {
        "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800"
    }

    // Helper to convert GraphQL coordinates to CLLocationCoordinate2D
    private func coordinatesFromGraphQL(_ coords: MapCoordinatesGraphQL) -> CLLocationCoordinate2D? {
        guard coords.coordinates.count >= 2 else { return nil }
        // GeoJSON format: [longitude, latitude]
        return CLLocationCoordinate2D(
            latitude: coords.coordinates[1],
            longitude: coords.coordinates[0]
        )
    }

    // Get coordinate for a store by ID
    func coordinate(for storeId: String) -> CLLocationCoordinate2D {
        return storeLocations[storeId] ?? CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666)
    }
}
