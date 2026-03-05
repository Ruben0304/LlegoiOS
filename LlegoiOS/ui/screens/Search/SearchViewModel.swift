//
//  SearchViewModel.swift
//  LlegoiOS
//
//  ViewModel para la pantalla de búsqueda
//

import Foundation
import SwiftUI
import MapKit
import Combine
import SwiftData

enum SearchState {
    case idle
    case loading
    case success
    case empty
    case error(String)
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var state: SearchState = .idle
    @Published var products: [Product] = []
    @Published var stores: [StoreWithCoordinates] = []
    @Published var storeProducts: [String: [ProductGraphQL]] = [:]
    @Published var selectedCategory: SearchCategory = .both

    // MARK: - Offline mode
    @Published var isOfflineMode: Bool = false

    private let searchRepository = SearchRepository()
    private let productRepository = ProductListRepository()
    private let storeRepository = StoreListRepository()
    private let branchTypeManager = BranchTypeManager.shared

    private var localSearchRepository: LocalSearchRepository?
    private var loadingProductsForStores: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    private var offlineSearchTask: Task<Void, Never>?

    private let defaultLogoUrl = ""
    private let defaultBannerUrl = ""

    // MARK: - Initialization
    init() {
        setupBranchTypeObserver()
        checkConnectivity()
    }

    // MARK: - Configure offline repository
    func configure(modelContext: ModelContext) {
        localSearchRepository = LocalSearchRepository(modelContext: modelContext)
    }

    // MARK: - Connectivity Check
    private func checkConnectivity() {
        // Detectar si hay conexión intentando alcanzar el backend
        // Para simplicidad usamos Network framework en background
        Task {
            let hasConnection = await checkInternetConnection()
            isOfflineMode = !hasConnection
        }
    }

    private func checkInternetConnection() async -> Bool {
        guard let url = URL(string: "https://llegobackend-production.up.railway.app/graphql") else {
            return false
        }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode != nil
        } catch {
            return false
        }
    }

    func setOfflineMode(_ offline: Bool) {
        isOfflineMode = offline
        loadInitialData()
    }

    // MARK: - Branch Type Observer
    private func setupBranchTypeObserver() {
        branchTypeManager.$selectedType
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.loadInitialData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Initial Data
    func loadInitialData() {
        state = .idle

        if isOfflineMode {
            loadInitialDataOffline()
            return
        }

        switch selectedCategory {
        case .products:
            loadInitialProducts()
        case .stores:
            loadInitialStores()
        case .both:
            state = .idle
        }
    }

    // MARK: - Offline initial data
    private func loadInitialDataOffline() {
        guard let localRepo = localSearchRepository else {
            state = .idle
            return
        }

        // Si no hay datos locales, quedarse en idle para que la UI muestre el prompt de descarga
        if !OfflineSyncService.shared.hasLocalData {
            state = .idle
            return
        }

        switch selectedCategory {
        case .products:
            let result = localRepo.loadInitialProducts()
            products = result
            state = products.isEmpty ? .empty : .idle

        case .stores:
            let (storesResult, storeProdsResult) = localRepo.loadInitialStores()
            stores = storesResult
            storeProducts = storeProdsResult
            state = stores.isEmpty ? .empty : .idle

        case .both:
            state = .idle
        }
    }

    // MARK: - Online initial data
    private func loadInitialProducts() {
        productRepository.fetchProducts(first: 20) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let (productsGraphQL, _)):
                    self.products = productsGraphQL.map { graphQL in
                        Product(
                            id: graphQL.id,
                            name: graphQL.name,
                            shop: graphQL.businessName,
                            shopLogoUrl: graphQL.businessLogoUrl,
                            weight: "",
                            price: graphQL.formattedPrice,
                            imageUrl: graphQL.imageUrl
                        )
                    }
                    self.state = self.products.isEmpty ? .empty : .idle
                case .failure(let error):
                    print("❌ Error loading initial products: \(error)")
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func loadInitialStores() {
        storeRepository.fetchBranches(first: 20) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let (branchesGraphQL, _)):
                    self.stores = branchesGraphQL.map { branch in
                        StoreWithCoordinates(
                            id: branch.id,
                            name: branch.name,
                            etaMinutes: self.calculateETA(deliveryRadius: branch.deliveryRadius),
                            logoUrl: branch.avatarUrl ?? self.defaultLogoUrl,
                            bannerUrl: branch.coverUrl ?? self.defaultBannerUrl,
                            address: branch.address,
                            rating: nil,
                            description: "Descripción de la tienda que estará disponible próximamente",
                            coordinate: CLLocationCoordinate2D(
                                latitude: branch.coordinates.latitude,
                                longitude: branch.coordinates.longitude
                            )
                        )
                    }
                    for branch in branchesGraphQL {
                        let mappedProducts = branch.products.prefix(4).map { product in
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
                    self.state = self.stores.isEmpty ? .empty : .idle
                case .failure(let error):
                    print("❌ Error loading initial stores: \(error)")
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Live search (offline only, llamado en onChange del texto)
    func searchLive(query: String) {
        guard isOfflineMode else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSearch()
            return
        }
        // Cancelar búsqueda anterior y lanzar nueva con pequeño debounce
        offlineSearchTask?.cancel()
        offlineSearchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms debounce
            guard !Task.isCancelled else { return }
            state = .loading
            searchOffline(query: trimmed)
        }
    }

    // MARK: - Search (online: solo al pulsar buscar; offline: también en tiempo real)
    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSearch()
            return
        }

        state = .loading

        if isOfflineMode {
            searchOffline(query: trimmed)
        } else {
            searchOnline(query: trimmed)
        }
    }

    // MARK: - Offline Search
    private func searchOffline(query: String) {
        guard let localRepo = localSearchRepository else {
            state = .error("Base de datos local no disponible")
            return
        }

        switch selectedCategory {
        case .products:
            let result = localRepo.searchProducts(query: query)
            products = result
            state = products.isEmpty ? .empty : .success

        case .stores:
            let (storesResult, storeProdsResult) = localRepo.searchStores(query: query)
            stores = storesResult
            storeProducts = storeProdsResult
            state = stores.isEmpty ? .empty : .success

        case .both:
            let result = localRepo.searchBoth(query: query)
            products = result.products
            stores = result.stores
            storeProducts = result.storeProducts
            state = (products.isEmpty && stores.isEmpty) ? .empty : .success
        }
    }

    // MARK: - Online Search
    private func searchOnline(query: String) {
        switch selectedCategory {
        case .products:
            searchProducts(query: query)
        case .stores:
            searchStores(query: query)
        case .both:
            searchBoth(query: query)
        }
    }

    private func searchBoth(query: String) {
        searchRepository.searchBoth(query: query) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let (products, stores, branchProducts)):
                    self.products = products
                    self.stores = stores
                    self.storeProducts = branchProducts
                    self.state = (products.isEmpty && stores.isEmpty) ? .empty : .success
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func searchProducts(query: String) {
        searchRepository.searchProducts(query: query) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let products):
                    self.products = products
                    self.state = products.isEmpty ? .empty : .success
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func searchStores(query: String) {
        searchRepository.searchBranches(query: query, first: 20) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let (storesData, products)):
                    self.stores = storesData
                    self.storeProducts = products
                    self.state = self.stores.isEmpty ? .empty : .success
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Clear Search
    func clearSearch() {
        loadInitialData()
    }

    // MARK: - Load Products for Store
    func loadProductsForStore(storeId: String) {
        guard !loadingProductsForStores.contains(storeId) else { return }
        loadingProductsForStores.insert(storeId)

        storeRepository.fetchBranchProducts(branchId: storeId, limit: 4) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.loadingProductsForStores.remove(storeId)
                switch result {
                case .success(let products):
                    self.storeProducts[storeId] = products
                case .failure:
                    self.storeProducts[storeId] = []
                }
            }
        }
    }

    func isLoadingProductsFor(storeId: String) -> Bool {
        loadingProductsForStores.contains(storeId)
    }

    // MARK: - Helpers
    private func calculateETA(deliveryRadius: Double?) -> Int {
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }
}
