import Foundation
import SwiftUI
import Combine
import MapKit

enum ShopTabLandingViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ShopTabLandingViewModel: ObservableObject {
    @Published var state: ShopTabLandingViewState = .idle
    @Published var stores: [StoreWithCoordinates] = []
    @Published var storeProducts: [String: [ShopProductGraphQL]] = [:] // storeId -> products
    @Published var isLoading: Bool = false
    @Published var isLoadingProducts: [String: Bool] = [:] // storeId -> isLoading

    private let repository = ShopTabLandingRepository()

    // Load all branches/stores
    func loadStores(isRefreshing: Bool = false) {
        // Solo mostrar loading si NO es un refresh
        if !isRefreshing {
            isLoading = true
            state = .loading
        }

        repository.fetchBranches { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let branchesGraphQL):
                    // Mapear branches GraphQL a modelos UI
                    self.stores = branchesGraphQL.map { branchGraphQL in
                        StoreWithCoordinates(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: self.calculateETA(
                                deliveryRadius: branchGraphQL.deliveryRadius
                            ),
                            logoUrl: branchGraphQL.avatarUrl ?? self.defaultLogoUrl,
                            bannerUrl: branchGraphQL.coverUrl ?? self.defaultBannerUrl,
                            address: branchGraphQL.address,
                            rating: nil, // TODO: Add rating when available in backend
                            coordinate: CLLocationCoordinate2D(
                                latitude: branchGraphQL.coordinates.latitude,
                                longitude: branchGraphQL.coordinates.longitude
                            )
                        )
                    }

                    self.isLoading = false
                    self.state = .success

                    // Load products for each store
                    for store in self.stores {
                        self.loadProductsForStore(storeId: store.id)
                    }

                case .failure(let error):
                    self.isLoading = false
                    self.state = .error("No se pudieron cargar las tiendas: \(error.localizedDescription)")
                }
            }
        }
    }

    // Load products for a specific store
    func loadProductsForStore(storeId: String) {
        isLoadingProducts[storeId] = true
        print("🛒 Cargando productos para tienda: \(storeId)")

        repository.fetchBranchProducts(branchId: storeId, limit: 2) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingProducts[storeId] = false

                switch result {
                case .success(let products):
                    print("✅ ViewModel recibió \(products.count) productos para tienda \(storeId)")
                    self.storeProducts[storeId] = products
                case .failure(let error):
                    print("❌ ViewModel falló al cargar productos para tienda \(storeId): \(error.localizedDescription)")
                    self.storeProducts[storeId] = []
                }
            }
        }
    }

    // Get products for a store
    func products(for storeId: String) -> [ShopProductGraphQL] {
        return storeProducts[storeId] ?? []
    }

    // Check if products are loading for a store
    func isLoadingProductsFor(storeId: String) -> Bool {
        return isLoadingProducts[storeId] ?? false
    }

    // Search stores by query
    func searchStores(query: String, completion: @escaping @Sendable ([StoreWithCoordinates]) -> Void) {
        repository.searchBranches(query: query, limit: 3) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let branchesGraphQL):
                    let searchResults = branchesGraphQL.map { branchGraphQL in
                        StoreWithCoordinates(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: self.calculateETA(
                                deliveryRadius: branchGraphQL.deliveryRadius
                            ),
                            logoUrl: branchGraphQL.avatarUrl ?? self.defaultLogoUrl,
                            bannerUrl: branchGraphQL.coverUrl ?? self.defaultBannerUrl,
                            address: branchGraphQL.address,
                            rating: nil,
                            coordinate: CLLocationCoordinate2D(
                                latitude: branchGraphQL.coordinates.latitude,
                                longitude: branchGraphQL.coordinates.longitude
                            )
                        )
                    }
                    completion(searchResults)

                case .failure(let error):
                    print("❌ Search failed: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateETA(deliveryRadius: Double?) -> Int {
        // Estimación simple: 5 minutos por km + 10 minutos base
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }

    private var defaultLogoUrl: String {
        "" // Empty string to trigger AsyncImage failure -> shows generic_logo asset
    }

    private var defaultBannerUrl: String {
        "" // Empty string to trigger AsyncImage failure -> shows generic_cover asset
    }
}
