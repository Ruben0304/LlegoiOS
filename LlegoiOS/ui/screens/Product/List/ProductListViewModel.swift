import Foundation
import SwiftUI
import Combine

struct ProductCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let isFeatured: Bool
    let isAll: Bool
}

enum SortOption: String, CaseIterable {
    case proximity = "Cercanía"
    case priceLowToHigh = "Precio: Menor a Mayor"
    case priceHighToLow = "Precio: Mayor a Menor"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .proximity:
            return "location.circle.fill"
        case .priceLowToHigh:
            return "arrow.up.circle.fill"
        case .priceHighToLow:
            return "arrow.down.circle.fill"
        }
    }
}

enum ProductListViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var state: ProductListViewState = .idle
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading: Bool = false

    // Paginación
    @Published var isLoadingMore: Bool = false
    @Published var currentCursor: String? = nil
    @Published var hasNextPage: Bool = false
    @Published var totalCount: Int = 0

    // Filtros
    @Published var maxDistance: Double = 50.0 // 50 = sin límite
    @Published var selectedCategory: String? = nil
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false

    // Ordenación
    @Published var sortOption: SortOption = .proximity

    // Branch filter
    var branchId: String? = nil

    // Categorías dinámicas desde el backend
    @Published var categories: [ProductCategory] = []
    @Published var isLoadingCategories: Bool = false

    // Flag para evitar recargar si ya se cargaron los datos
    private var hasLoaded: Bool = false

    private let repository = ProductListRepository()
    private let userLocationManager = UserLocationManager.shared
    private let branchTypeManager = BranchTypeManager.shared

    var hasActiveFilters: Bool {
        maxDistance < 50 || selectedCategory != nil || !searchQuery.isEmpty
    }
    
    /// Radio efectivo para las queries (nil si es 50 o más)
    private var effectiveRadiusKm: Double? {
        maxDistance < 50 ? maxDistance : nil
    }
    
    init() {
        // Cargar el radio guardado del UserLocationManager
        if let savedRadius = userLocationManager.searchRadiusKm {
            maxDistance = savedRadius
        }
    }

    func loadCategories() {
        isLoadingCategories = true

        // Obtener el tipo de negocio actual
        let branchType = branchTypeManager.selectedType.rawValue

        repository.fetchProductCategories(branchType: branchType) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingCategories = false

                switch result {
                case .success(let categoriesGraphQL):
                    // Siempre agregar la opción "Todos" al principio
                    var mappedCategories: [ProductCategory] = [
                        ProductCategory(
                            id: "all",
                            name: "Todos",
                            icon: "square.grid.2x2",
                            isFeatured: false,
                            isAll: true
                        )
                    ]

                    // Mapear categorías del backend
                    let backendCategories = categoriesGraphQL.map { categoryGraphQL in
                        ProductCategory(
                            id: categoryGraphQL.id,
                            name: categoryGraphQL.name,
                            icon: categoryGraphQL.iconIos,
                            isFeatured: false,
                            isAll: false
                        )
                    }

                    mappedCategories.append(contentsOf: backendCategories)
                    self.categories = mappedCategories

                    print("✅ Loaded \(backendCategories.count) categories (+ 'Todos') for branch type: \(branchType)")

                case .failure(let error):
                    print("❌ Error loading categories: \(error.localizedDescription)")
                    // Si falla, solo mostrar "Todos"
                    self.categories = [
                        ProductCategory(
                            id: "all",
                            name: "Todos",
                            icon: "square.grid.2x2",
                            isFeatured: false,
                            isAll: true
                        )
                    ]
                }
            }
        }
    }

    func loadProducts(isRefreshing: Bool = false) {
        // Evitar recargar si ya se cargaron los datos (excepto en refresh explícito o cuando hay branchId)
        if hasLoaded && !isRefreshing && branchId == nil {
            print("📦 ProductListViewModel - Datos ya cargados, omitiendo recarga")
            return
        }

        // Reset pagination state on refresh
        if isRefreshing {
            currentCursor = nil
            hasNextPage = false
            totalCount = 0
            products = []
            filteredProducts = []
            hasLoaded = false
        }

        // Solo mostrar loading si NO es un refresh
        if !isRefreshing {
            isLoading = true
            state = .loading
        }
        
        print("📦 ProductListViewModel.loadProducts - branchId: \(branchId ?? "nil"), isRefreshing: \(isRefreshing), hasLoaded: \(hasLoaded)")

        repository.fetchProducts(first: 8, after: nil, branchId: branchId, radiusKm: effectiveRadiusKm) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let (productsGraphQL, pageInfo)):
                    // Mapear productos GraphQL a modelos UI
                    self.products = productsGraphQL.map { productGraphQL in
                        Product(
                            id: productGraphQL.id,
                            name: productGraphQL.name,
                            shop: productGraphQL.businessName,
                            shopLogoUrl: productGraphQL.businessLogoUrl,
                            weight: "0",
                            price: self.formatPrice(
                                price: productGraphQL.price,
                                currency: productGraphQL.currency
                            ),
                            imageUrl: productGraphQL.imageUrl
                        )
                    }

                    // Update pagination state
                    self.currentCursor = pageInfo.endCursor
                    self.hasNextPage = pageInfo.hasNextPage
                    self.totalCount = pageInfo.totalCount

                    self.applyFiltersAndSort()

                    // Marcar como completado
                    self.isLoading = false
                    self.hasLoaded = true
                    if !isRefreshing {
                        self.state = .success
                    }

                    print("✅ Loaded \(self.products.count) products (hasNextPage: \(pageInfo.hasNextPage), totalCount: \(pageInfo.totalCount))" + (self.branchId != nil ? " for branch \(self.branchId!)" : ""))

                case .failure(let error):
                    self.isLoading = false

                    // Mejorar mensaje de error para offline
                    let nsError = error as NSError
                    let isNetworkError = nsError.domain == NSURLErrorDomain &&
                        (nsError.code == NSURLErrorNotConnectedToInternet ||
                         nsError.code == NSURLErrorTimedOut ||
                         nsError.code == NSURLErrorCannotConnectToHost ||
                         nsError.code == NSURLErrorNetworkConnectionLost)

                    let errorMessage = isNetworkError
                        ? "No hay conexión a internet y no hay productos guardados en caché"
                        : "Error al cargar productos: \(error.localizedDescription)"

                    print("❌ ShopViewModel error: \(errorMessage)")
                    self.state = .error(errorMessage)
                }
            }
        }
    }

    func applyFilters() {
        // Cuando cambia el radio, recargar productos del backend
        loadProducts(isRefreshing: true)
    }

    func applySort() {
        applyFiltersAndSort()
    }

    func loadMoreProducts() {
        guard !isLoadingMore, hasNextPage, let cursor = currentCursor else {
            print("📦 loadMoreProducts - Skipping (isLoadingMore: \(isLoadingMore), hasNextPage: \(hasNextPage), cursor: \(currentCursor ?? "nil"))")
            return
        }

        print("📦 loadMoreProducts - Loading next page with cursor: \(cursor)")
        isLoadingMore = true

        repository.fetchProducts(first: 8, after: cursor, branchId: branchId, radiusKm: effectiveRadiusKm) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoadingMore = false

                switch result {
                case .success(let (productsGraphQL, pageInfo)):
                    // Mapear productos GraphQL a modelos UI
                    let newProducts = productsGraphQL.map { productGraphQL in
                        Product(
                            id: productGraphQL.id,
                            name: productGraphQL.name,
                            shop: productGraphQL.businessName,
                            shopLogoUrl: productGraphQL.businessLogoUrl,
                            weight: "0",
                            price: self.formatPrice(
                                price: productGraphQL.price,
                                currency: productGraphQL.currency
                            ),
                            imageUrl: productGraphQL.imageUrl
                        )
                    }

                    // Append new products to existing list
                    self.products.append(contentsOf: newProducts)

                    // Update pagination state
                    self.currentCursor = pageInfo.endCursor
                    self.hasNextPage = pageInfo.hasNextPage

                    self.applyFiltersAndSort()

                    print("✅ Loaded \(newProducts.count) more products (total: \(self.products.count), hasNextPage: \(pageInfo.hasNextPage))")

                case .failure(let error):
                    print("❌ Error loading more products: \(error.localizedDescription)")
                }
            }
        }
    }

    func loadMoreIfNeeded(currentItem: Product?) {
        guard let currentItem = currentItem else {
            loadMoreProducts()
            return
        }

        let thresholdIndex = filteredProducts.index(filteredProducts.endIndex, offsetBy: -3)
        if let currentIndex = filteredProducts.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= thresholdIndex {
            loadMoreProducts()
        }
    }

    func clearFilters() {
        maxDistance = 50.0
        selectedCategory = nil
        searchQuery = ""
        applyFiltersAndSort()
    }

    // Execute search (called when user submits search)
    func executeSearch() {
        print("🔍 executeSearch() - query: '\(searchQuery)'")
        if !searchQuery.isEmpty {
            performVectorSearch()
        } else {
            // If search is empty, show all products with current filters
            print("🔍 Search query is empty, applying local filters")
            applyFiltersAndSort()
        }
    }

    // Perform vector search using GraphQL
    private func performVectorSearch() {
        guard !searchQuery.isEmpty else {
            applyFiltersAndSort()
            return
        }

        print("🔍 performVectorSearch() - Starting search for: '\(searchQuery)'")
        isSearching = true

        repository.searchProducts(query: searchQuery, first: 50, after: nil, branchId: branchId, radiusKm: effectiveRadiusKm) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                self.isSearching = false

                switch result {
                case .success(let (productsGraphQL, pageInfo)):
                    print("✅ Vector search returned \(productsGraphQL.count) products (hasNextPage: \(pageInfo.hasNextPage))")

                    // Map to UI models
                    let searchResults = productsGraphQL.map { productGraphQL in
                        Product(
                            id: productGraphQL.id,
                            name: productGraphQL.name,
                            shop: productGraphQL.businessName,
                            shopLogoUrl: productGraphQL.businessLogoUrl,
                            weight: "0",
                            price: self.formatPrice(
                                price: productGraphQL.price,
                                currency: productGraphQL.currency
                            ),
                            imageUrl: productGraphQL.imageUrl
                        )
                    }

                    print("🔍 Mapped to \(searchResults.count) UI products")

                    // Update pagination state for search
                    self.currentCursor = pageInfo.endCursor
                    self.hasNextPage = pageInfo.hasNextPage
                    self.totalCount = pageInfo.totalCount

                    // Apply filters and sorting to search results
                    self.applyFiltersAndSort(to: searchResults)

                    print("🔍 Final filtered products: \(self.filteredProducts.count)")

                case .failure(let error):
                    let nsError = error as NSError
                    
                    // Check if it's a rate limit error
                    if nsError.domain == "RateLimit" && nsError.code == 429 {
                        print("⏱️ Rate limit alcanzado en búsqueda de productos")
                        print("💡 Sugerencia: El backend está limitando las búsquedas a 10 por minuto")
                        // Show user-friendly message
                        self.state = .error("Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo.")
                    } else {
                        print("❌ Vector search failed: \(error.localizedDescription)")
                        // Fallback to local filtering if search fails
                        self.applyFiltersAndSort()
                    }
                }
            }
        }
    }

    private func applyFiltersAndSort(to sourceProducts: [Product]? = nil) {
        var result = sourceProducts ?? products
        print("🔍 applyFiltersAndSort() - Input: \(result.count) products")

        // Note: When using vector search, text search is already done by the backend
        // So we skip the local text search when sourceProducts is provided

        // Aplicar filtro de categoría
        if let category = selectedCategory {
            result = result.filter { product in
                // Filtrar por nombre del producto que contenga la categoría
                product.name.localizedCaseInsensitiveContains(category) ||
                category.localizedCaseInsensitiveContains(product.name)
            }
        }

        // El filtro de distancia ahora se aplica en el backend via radiusKm
        // No necesitamos filtrar localmente

        // Aplicar ordenación
        switch sortOption {
        case .proximity:
            // TODO: Ordenar por distancia real cuando tengamos coordenadas
            // Por ahora, dejar el orden original
            break

        case .priceLowToHigh:
            result = result.sorted { product1, product2 in
                extractPrice(from: product1.price) < extractPrice(from: product2.price)
            }

        case .priceHighToLow:
            result = result.sorted { product1, product2 in
                extractPrice(from: product1.price) > extractPrice(from: product2.price)
            }
        }

        filteredProducts = result
        print("🔍 applyFiltersAndSort() - Output: \(filteredProducts.count) products")
    }

    // MARK: - Helper Methods

    private func formatPrice(price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = getCurrencySymbol(for: currency)
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(getCurrencySymbol(for: currency))\(price)"
    }

    private func getCurrencySymbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "CUP": return "$"
        default: return "$"
        }
    }

    private func extractPrice(from priceString: String) -> Double {
        // Extraer el precio numérico de un string como "$12.50"
        let cleanedString = priceString
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanedString) ?? 0.0
    }
}
