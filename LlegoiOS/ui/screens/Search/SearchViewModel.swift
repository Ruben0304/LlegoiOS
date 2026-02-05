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
    @Published var selectedCategory: SearchCategory = .products

    private let searchRepository = SearchRepository()
    private let productRepository = ProductListRepository()
    private let storeRepository = StoreListRepository()
    private let branchTypeManager = BranchTypeManager.shared

    private var loadingProductsForStores: Set<String> = []
    private var cancellables = Set<AnyCancellable>()

    // Default images
    private let defaultLogoUrl = ""
    private let defaultBannerUrl = ""

    // MARK: - Initialization
    init() {
        setupBranchTypeObserver()
    }

    // MARK: - Branch Type Observer

    private func setupBranchTypeObserver() {
        branchTypeManager.$selectedType
            .dropFirst() // Ignore initial value
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("🔄 SearchViewModel - Branch type changed, reloading data")
                self.loadInitialData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Initial Data
    func loadInitialData() {
        print("🔍 SearchViewModel - loadInitialData() called, selectedCategory: \(selectedCategory)")
        state = .idle

        switch selectedCategory {
        case .products:
            print("🔍 SearchViewModel - Loading initial products...")
            loadInitialProducts()
        case .stores:
            print("🔍 SearchViewModel - Loading initial stores...")
            loadInitialStores()
        }
    }
    
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
                            coordinate: CLLocationCoordinate2D(
                                latitude: branch.coordinates.latitude,
                                longitude: branch.coordinates.longitude
                            )
                        )
                    }
                    
                    // Mapear productos anidados (solo los primeros 4)
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
    
    // MARK: - Search (solo cuando se presiona buscar)
    func search(query: String) {
        print("🔍 SearchViewModel - search() called with query: '\(query)'")
        print("🔍 SearchViewModel - selectedCategory: \(selectedCategory)")

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ SearchViewModel - Query is empty after trimming, clearing search")
            clearSearch()
            return
        }

        print("✅ SearchViewModel - Query valid, setting state to loading")
        state = .loading

        switch selectedCategory {
        case .products:
            print("🔍 SearchViewModel - Searching products...")
            searchProducts(query: query)
        case .stores:
            print("🔍 SearchViewModel - Searching stores...")
            searchStores(query: query)
        }
    }
    
    private func searchProducts(query: String) {
        print("🔍 SearchViewModel - searchProducts() calling repository with query: '\(query)'")
        searchRepository.searchProducts(query: query) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let products):
                    print("✅ SearchViewModel - Products search SUCCESS, found \(products.count) products")
                    print("📦 SearchViewModel - Products: \(products.map { $0.name }.joined(separator: ", "))")
                    self.products = products
                    self.state = products.isEmpty ? .empty : .success
                    print("🔍 SearchViewModel - State set to: \(products.isEmpty ? "empty" : "success")")

                case .failure(let error):
                    print("❌ SearchViewModel - Products search FAILED: \(error.localizedDescription)")
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func searchStores(query: String) {
        print("🔍 SearchViewModel - searchStores() calling repository with query: '\(query)'")
        searchRepository.searchBranches(query: query, first: 20) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let (storesData, products)):
                    print("✅ SearchViewModel - Stores search SUCCESS, found \(storesData.count) stores")
                    print("🏪 SearchViewModel - Stores: \(storesData.map { $0.name }.joined(separator: ", "))")
                    print("📦 SearchViewModel - Productos anidados recibidos para \(products.count) tiendas")

                    // Asignar tiendas y productos directamente
                    self.stores = storesData
                    self.storeProducts = products

                    self.state = self.stores.isEmpty ? .empty : .success
                    print("🔍 SearchViewModel - State set to: \(self.stores.isEmpty ? "empty" : "success")")
                    print("✅ SearchViewModel - Optimización: productos cargados en 1 sola llamada (antes eran N+1)")

                case .failure(let error):
                    print("❌ SearchViewModel - Stores search FAILED: \(error.localizedDescription)")
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Clear Search
    func clearSearch() {
        print("🔍 SearchViewModel - clearSearch() called, reloading initial data")
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
