import Foundation
import SwiftUI
import Combine

// MARK: - View State
enum SearchViewState {
    case idle
    case loading
    case success
    case error(String)
}

// MARK: - SearchViewModel
@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: SearchViewState = .idle
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
    private let repository = SearchRepository()

    // Default images for stores (since backend doesn't provide them)
    private let defaultLogoUrl = "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
    private let defaultBannerUrl = "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"

    // Task management for search debouncing
    private var searchTask: Task<Void, Never>?

    // MARK: - Public Methods

    /// Search products by query
    func searchProducts(query: String) {
        // Cancel any previous search task
        searchTask?.cancel()

        // If query is empty, clear results
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            products = []
            state = .idle
            return
        }

        state = .loading
        errorMessage = nil

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if task was cancelled
            if Task.isCancelled { return }

            repository.searchProducts(query: query) { [weak self] result in
                guard let self = self else { return }

                Task { @MainActor in
                    // Check again if task was cancelled
                    if Task.isCancelled { return }

                    switch result {
                    case .success(let productsGraphQL):
                        // Map GraphQL products to UI Product model
                        self.products = productsGraphQL.map { productGraphQL in
                            Product(
                                id: productGraphQL.id, // Use real GraphQL ID
                                name: productGraphQL.name,
                                shop: "Store", // Will be updated when we link products to branches
                                weight: productGraphQL.weight,
                                price: self.formatPrice(price: productGraphQL.price, currency: productGraphQL.currency),
                                imageUrl: productGraphQL.image
                            )
                        }

                        self.state = .success
                        print("✅ SearchViewModel: Found \(self.products.count) products for query: \(query)")

                    case .failure(let error):
                        let message = "Error al buscar productos: \(error.localizedDescription)"
                        self.errorMessage = message
                        self.state = .error(message)
                        self.products = []
                        print("❌ SearchViewModel: \(message)")
                    }
                }
            }
        }
    }

    /// Search stores (branches) by query
    func searchStores(query: String) {
        // Cancel any previous search task
        searchTask?.cancel()

        // If query is empty, clear results
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            stores = []
            state = .idle
            return
        }

        state = .loading
        errorMessage = nil

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if task was cancelled
            if Task.isCancelled { return }

            repository.searchBranches(query: query) { [weak self] result in
                guard let self = self else { return }

                Task { @MainActor in
                    // Check again if task was cancelled
                    if Task.isCancelled { return }

                    switch result {
                    case .success(let branchesGraphQL):
                        // Map GraphQL branches to UI Store model
                        self.stores = branchesGraphQL.map { branchGraphQL in
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
                        print("✅ SearchViewModel: Found \(self.stores.count) stores for query: \(query)")

                    case .failure(let error):
                        let message = "Error al buscar negocios: \(error.localizedDescription)"
                        self.errorMessage = message
                        self.state = .error(message)
                        self.stores = []
                        print("❌ SearchViewModel: \(message)")
                    }
                }
            }
        }
    }

    /// Perform search based on selected category
    func performSearch(query: String, category: SearchCategory) {
        switch category {
        case .products:
            searchProducts(query: query)
        case .stores:
            searchStores(query: query)
        }
    }

    /// Cancel any ongoing search
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
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
