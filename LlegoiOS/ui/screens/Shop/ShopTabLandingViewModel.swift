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
    @Published var isLoading: Bool = false

    private let repository = ShopTabLandingRepository()

    // Load all branches/stores
    func loadStores() {
        isLoading = true
        state = .loading

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

                case .failure(let error):
                    self.isLoading = false
                    self.state = .error("No se pudieron cargar las tiendas: \(error.localizedDescription)")
                }
            }
        }
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
        "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
    }

    private var defaultBannerUrl: String {
        "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
    }
}
