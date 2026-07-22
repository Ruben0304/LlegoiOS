//
//  SearchViewModel.swift
//  LlegoiOS
//
//  ViewModel para la pantalla de búsqueda
//
//  La búsqueda siempre intenta primero por internet. Si la respuesta tarda
//  más de 15s o falla, y hay datos descargados localmente, se pasa
//  automáticamente a búsqueda offline (mostrando un aviso). Si no hay datos
//  locales, se muestra un estado de "sin conexión" con botón de reintentar.
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

private struct SearchTimeoutError: Error {}

/// Corre `operation` con un límite de tiempo; si no responde a tiempo, lanza `SearchTimeoutError`.
private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw SearchTimeoutError()
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else {
            throw SearchTimeoutError()
        }
        return result
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var state: SearchState = .idle
    @Published var products: [Product] = []
    @Published var stores: [StoreWithCoordinates] = []
    @Published var storeProducts: [String: [ProductGraphQL]] = [:]
    @Published var selectedCategory: SearchCategory = .both

    /// True cuando los resultados mostrados vienen de datos locales porque el
    /// intento por internet falló o tardó demasiado (no es un toggle manual).
    @Published var isShowingOfflineFallback: Bool = false

    private let searchRepository = SearchRepository()
    private let productRepository = ProductListRepository()
    private let storeRepository = StoreListRepository()
    private let branchTypeManager = BranchTypeManager.shared

    private var localSearchRepository: LocalSearchRepository?
    private var loadingProductsForStores: Set<String> = []
    private var cancellables = Set<AnyCancellable>()
    private var offlineSearchTask: Task<Void, Never>?
    private var currentRequestTask: Task<Void, Never>?

    /// Se incrementa en cada nuevo loadInitialData()/search(); usado para descartar
    /// respuestas de intentos ya superados (p. ej. el usuario cambió de categoría
    /// mientras un intento anterior seguía esperando el timeout).
    private var requestGeneration = 0

    private let onlineTimeoutSeconds: TimeInterval = 15

    // MARK: - Initialization
    init() {
        setupBranchTypeObserver()
    }

    // MARK: - Configure offline repository
    func configure(modelContext: ModelContext) {
        localSearchRepository = LocalSearchRepository(modelContext: modelContext)
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
        requestGeneration += 1
        let generation = requestGeneration
        currentRequestTask?.cancel()
        currentRequestTask = Task { [weak self] in
            await self?.performLoadInitialData(generation: generation)
        }
    }

    private func performLoadInitialData(generation: Int) async {
        state = .loading

        do {
            switch selectedCategory {
            case .products:
                let result = try await withTimeout(seconds: onlineTimeoutSeconds) {
                    try await self.fetchInitialProductsOnline()
                }
                guard generation == requestGeneration else { return }
                products = result
                state = products.isEmpty ? .empty : .idle
                isShowingOfflineFallback = false

            case .stores:
                let (storesResult, storeProdsResult) = try await withTimeout(seconds: onlineTimeoutSeconds) {
                    try await self.fetchInitialStoresOnline()
                }
                guard generation == requestGeneration else { return }
                stores = storesResult
                storeProducts = storeProdsResult
                state = stores.isEmpty ? .empty : .idle
                isShowingOfflineFallback = false

            case .both:
                guard generation == requestGeneration else { return }
                state = .idle
                isShowingOfflineFallback = false
            }
        } catch {
            guard generation == requestGeneration else { return }
            print("❌ loadInitialData online falló/timeout: \(error)")
            fallbackAfterOnlineFailure(offline: { [weak self] in self?.loadInitialDataOffline() })
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

    // MARK: - Fallback helper

    /// Decide qué mostrar cuando el intento online falla o hace timeout:
    /// si hay datos locales, cae a offline (con aviso); si no, error de sin conexión.
    private func fallbackAfterOnlineFailure(offline: @escaping () -> Void) {
        if OfflineSyncService.shared.hasLocalData {
            isShowingOfflineFallback = true
            offline()
        } else {
            isShowingOfflineFallback = false
            state = .error("No hay conexión a internet. Descarga los datos primero para buscar sin conexión.")
        }
    }

    // MARK: - Online fetch wrappers (no tocan estado del ViewModel; solo devuelven datos)

    private func fetchInitialProductsOnline() async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            productRepository.fetchProducts(first: 20) { result in
                switch result {
                case .success(let (productsGraphQL, _)):
                    let mapped = productsGraphQL.map { graphQL in
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
                    continuation.resume(returning: mapped)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchInitialStoresOnline() async throws -> ([StoreWithCoordinates], [String: [ProductGraphQL]]) {
        try await withCheckedThrowingContinuation { continuation in
            storeRepository.fetchBranches(first: 20) { [weak self] result in
                guard let self = self else {
                    continuation.resume(returning: ([], [:]))
                    return
                }
                switch result {
                case .success(let (branchesGraphQL, _)):
                    let mappedStores = branchesGraphQL.map { branch in
                        StoreWithCoordinates(
                            id: branch.id,
                            name: branch.name,
                            etaMinutes: self.calculateETA(deliveryRadius: branch.deliveryRadius),
                            logoUrl: branch.preferredAvatarSmallUrl ?? "",
                            bannerUrl: branch.preferredCoverFastUrl ?? "",
                            address: branch.address,
                            rating: nil,
                            description: branch.description,
                            coordinate: CLLocationCoordinate2D(
                                latitude: branch.coordinates.latitude,
                                longitude: branch.coordinates.longitude
                            )
                        )
                    }
                    var storeProds: [String: [ProductGraphQL]] = [:]
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
                        storeProds[branch.id] = mappedProducts
                    }
                    continuation.resume(returning: (mappedStores, storeProds))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Live search (offline only, llamado en onChange del texto)
    func searchLive(query: String) {
        guard isShowingOfflineFallback else { return }
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

    // MARK: - Search (siempre intenta por internet primero)
    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearSearch()
            return
        }

        requestGeneration += 1
        let generation = requestGeneration
        currentRequestTask?.cancel()
        currentRequestTask = Task { [weak self] in
            await self?.performSearch(query: trimmed, generation: generation)
        }
    }

    private func performSearch(query: String, generation: Int) async {
        state = .loading

        do {
            switch selectedCategory {
            case .products:
                let result = try await withTimeout(seconds: onlineTimeoutSeconds) {
                    try await self.fetchSearchProductsOnline(query: query)
                }
                guard generation == requestGeneration else { return }
                products = result
                state = products.isEmpty ? .empty : .success
                isShowingOfflineFallback = false

            case .stores:
                let (storesResult, storeProdsResult) = try await withTimeout(seconds: onlineTimeoutSeconds) {
                    try await self.fetchSearchStoresOnline(query: query)
                }
                guard generation == requestGeneration else { return }
                stores = storesResult
                storeProducts = storeProdsResult
                state = stores.isEmpty ? .empty : .success
                isShowingOfflineFallback = false

            case .both:
                let (productsResult, storesResult, storeProdsResult) = try await withTimeout(seconds: onlineTimeoutSeconds) {
                    try await self.fetchSearchBothOnline(query: query)
                }
                guard generation == requestGeneration else { return }
                products = productsResult
                stores = storesResult
                storeProducts = storeProdsResult
                state = (products.isEmpty && stores.isEmpty) ? .empty : .success
                isShowingOfflineFallback = false
            }
        } catch {
            guard generation == requestGeneration else { return }
            print("❌ search online falló/timeout: \(error)")
            fallbackAfterOnlineFailure(offline: { [weak self] in self?.searchOffline(query: query) })
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

    // MARK: - Online search wrappers (no tocan estado del ViewModel; solo devuelven datos)

    private func fetchSearchProductsOnline(query: String) async throws -> [Product] {
        try await withCheckedThrowingContinuation { continuation in
            searchRepository.searchProducts(query: query) { result in
                switch result {
                case .success(let products):
                    continuation.resume(returning: products)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchSearchStoresOnline(query: String) async throws -> ([StoreWithCoordinates], [String: [ProductGraphQL]]) {
        try await withCheckedThrowingContinuation { continuation in
            searchRepository.searchBranches(query: query, first: 20) { result in
                switch result {
                case .success(let (storesData, products)):
                    continuation.resume(returning: (storesData, products))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetchSearchBothOnline(query: String) async throws -> ([Product], [StoreWithCoordinates], [String: [ProductGraphQL]]) {
        try await withCheckedThrowingContinuation { continuation in
            searchRepository.searchBoth(query: query) { result in
                switch result {
                case .success(let (products, stores, branchProducts)):
                    continuation.resume(returning: (products, stores, branchProducts))
                case .failure(let error):
                    continuation.resume(throwing: error)
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
    /// No toca estado del actor — puede llamarse desde closures de red que no corren en el main actor.
    nonisolated private func calculateETA(deliveryRadius: Double?) -> Int {
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }
}
