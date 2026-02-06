import Foundation
import SwiftUI
import Combine
import MapKit

enum StoreListViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class StoreListViewModel: ObservableObject {
    @Published var state: StoreListViewState = .idle
    @Published var stores: [StoreWithCoordinates] = []
    @Published var storeProducts: [String: [ProductGraphQL]] = [:] // storeId -> products
    @Published var isLoading: Bool = false
    @Published var isLoadingProducts: [String: Bool] = [:] // storeId -> isLoading

    // Paginación
    @Published var isLoadingMore: Bool = false
    @Published var currentCursor: String? = nil
    @Published var hasNextPage: Bool = false
    @Published var totalCount: Int = 0

    // Flag para evitar recargar si ya se cargaron los datos
    private var hasLoaded: Bool = false

    private let repository = StoreListRepository()

    // Load all branches/stores
    func loadStores(isRefreshing: Bool = false) {
        // Evitar recargar si ya se cargaron los datos (excepto en refresh explícito)
        if hasLoaded && !isRefreshing {
            print("🏪 StoreListViewModel - Datos ya cargados, omitiendo recarga")
            return
        }

        // Reset pagination state on refresh
        if isRefreshing {
            currentCursor = nil
            hasNextPage = false
            totalCount = 0
        }

        // Solo mostrar loading si NO es un refresh
        if !isRefreshing {
            isLoading = true
            state = .loading
        }

        repository.fetchBranches(first: 20, after: nil) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let (branchesGraphQL, pageInfo)):
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

                    // Update pagination state
                    self.currentCursor = pageInfo.endCursor
                    self.hasNextPage = pageInfo.hasNextPage
                    self.totalCount = pageInfo.totalCount

                    self.isLoading = false
                    self.hasLoaded = true
                    self.state = .success

                    // Los productos ya vienen anidados en la query, no necesitamos queries adicionales
                    // Mapear productos anidados al diccionario storeProducts
                    for branch in branchesGraphQL {
                        let mappedProducts = branch.products.map { product in
                            ProductGraphQL(
                                id: product.id,
                                branchId: branch.id,
                                name: product.name,
                                price: product.price,
                                currency: product.currency,
                                imageUrl: product.imageUrl,
                                availability: true,
                                createdAt: "",
                                businessName: branch.name,
                                distanceKm: nil,
                                categoryId: nil,
                                categoryName: nil
                            )
                        }
                        self.storeProducts[branch.id] = mappedProducts
                    }

                    print("✅ Loaded \(branchesGraphQL.count) stores (hasNextPage: \(pageInfo.hasNextPage), totalCount: \(pageInfo.totalCount))")

                case .failure(let error):
                    self.isLoading = false
                    self.state = .error("No se pudieron cargar las tiendas: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadMoreStores() {
        guard !isLoadingMore, hasNextPage, let cursor = currentCursor else {
            print("🏪 loadMoreStores - Skipping (isLoadingMore: \(isLoadingMore), hasNextPage: \(hasNextPage), cursor: \(currentCursor ?? "nil"))")
            return
        }

        print("🏪 loadMoreStores - Loading next page with cursor: \(cursor)")
        isLoadingMore = true

        repository.fetchBranches(first: 20, after: cursor) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingMore = false

                switch result {
                case .success(let (branchesGraphQL, pageInfo)):
                    // Mapear branches GraphQL a modelos UI
                    let newStores = branchesGraphQL.map { branchGraphQL in
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

                    // Append new stores to existing list
                    self.stores.append(contentsOf: newStores)

                    // Update pagination state
                    self.currentCursor = pageInfo.endCursor
                    self.hasNextPage = pageInfo.hasNextPage

                    // Mapear productos anidados
                    for branch in branchesGraphQL {
                        let mappedProducts = branch.products.map { product in
                            ProductGraphQL(
                                id: product.id,
                                branchId: branch.id,
                                name: product.name,
                                price: product.price,
                                currency: product.currency,
                                imageUrl: product.imageUrl,
                                availability: true,
                                createdAt: "",
                                businessName: branch.name,
                                distanceKm: nil,
                                categoryId: nil,
                                categoryName: nil
                            )
                        }
                        self.storeProducts[branch.id] = mappedProducts
                    }

                    print("✅ Loaded \(newStores.count) more stores (total: \(self.stores.count), hasNextPage: \(pageInfo.hasNextPage))")

                case .failure(let error):
                    print("❌ Error loading more stores: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadMoreIfNeeded(currentStore: StoreWithCoordinates?) {
        guard let currentStore = currentStore else {
            loadMoreStores()
            return
        }

        let thresholdIndex = stores.index(stores.endIndex, offsetBy: -3)
        if let currentIndex = stores.firstIndex(where: { $0.id == currentStore.id }),
           currentIndex >= thresholdIndex {
            loadMoreStores()
        }
    }

    // REMOVED: loadProductsForStore() - Products are now loaded with nested queries in loadStores() and loadMoreStores()
    // No need for separate product fetching since GetBranches.graphql already includes products

    // Get products for a store
    func products(for storeId: String) -> [ProductGraphQL] {
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

                    // Map nested products from search results to storeProducts dictionary
                    for branch in branchesGraphQL {
                        let mappedProducts = branch.products.map { product in
                            ProductGraphQL(
                                id: product.id,
                                branchId: branch.id,
                                name: product.name,
                                price: product.price,
                                currency: product.currency,
                                imageUrl: product.imageUrl,
                                availability: true,
                                createdAt: "",
                                businessName: branch.name,
                                distanceKm: nil,
                                categoryId: nil,
                                categoryName: nil
                            )
                        }
                        self.storeProducts[branch.id] = mappedProducts
                    }

                    completion(searchResults)

                case .failure(let error):
                    let nsError = error as NSError
                    
                    // Check if it's a rate limit error
                    if nsError.domain == "RateLimit" && nsError.code == 429 {
                        print("⏱️ Rate limit alcanzado en búsqueda de tiendas")
                        print("💡 Sugerencia: El backend está limitando las búsquedas a 10 por minuto")
                        self.state = .error("Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo.")
                    } else {
                        print("❌ Search failed: \(error.localizedDescription)")
                    }
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
