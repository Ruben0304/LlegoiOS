import Combine
import Foundation
import SwiftUI

enum ProductFeedViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ProductFeedViewModel: ObservableObject {

    // MARK: - Section Layout

    /// Controls the render order of all feed sections.
    /// Reorder this array to change how sections appear on screen.
    enum SectionSlot: CaseIterable, Hashable {
        case paraTi
        case pideDeNuevo
        case dynamicFirst
        case stores
        case combos
        case dynamicRest
        case tutorials
    }

    let sectionOrder: [SectionSlot] = [
        .paraTi, .pideDeNuevo, .dynamicFirst, .stores, .combos, .dynamicRest, .tutorials,
    ]

    // MARK: - Published Properties
    @Published var state: ProductFeedViewState = .idle
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false

    // New dynamic sections from feed API
    @Published var feedSections: [FeedSection] = []

    // Legacy data (categories, stores - still loaded separately)
    @Published var categories: [FeedCategory] = []
    @Published var stores: [FeedStore] = []

    // Legacy product arrays (kept for backward compatibility, populated from feed sections)
    @Published var featuredProducts: [FeedProduct] = []
    @Published var recentProducts: [FeedProduct] = []
    @Published var popularProducts: [FeedProduct] = []

    // Reorder items for "Pide de nuevo" section (auth-gated)
    @Published var reorderItems: [ReorderItem] = []

    // Filters
    @Published var selectedCategory: String? = nil

    // Pagination
    @Published var hasNextPage: Bool = false
    @Published var currentCursor: String? = nil

    // Tutorials visibility
    @Published var showTutorials: Bool = true

    // Real tutorials from backend (activeTutorials query)
    @Published var tutorials: [Tutorial] = []

    // Combos from backend
    @Published var combos: [FeedCombo] = []

    // MARK: - Private Properties
    private var hasLoaded: Bool = false
    private let repository = ProductFeedRepository()
    private let branchTypeManager = BranchTypeManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        showTutorials = TutorialsHelper.areTutorialsVisible
        setupBranchTypeObserver()
    }

    // MARK: - Branch Type Observer

    private func setupBranchTypeObserver() {
        branchTypeManager.$selectedType
            .dropFirst()  // Ignore initial value
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.loadFeed(isRefreshing: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func loadFeed(isRefreshing: Bool = false) {
        if isRefreshing {
            currentCursor = nil
            hasNextPage = false
            hasLoaded = false
            reorderItems = []
        }

        if !isRefreshing {
            isLoading = true
            state = .loading
        }

        Task {
            // 🚀 OPTIMIZATION: Single GraphQL query instead of 3 separate calls
            let result = await repository.fetchCompleteFeed(
                first: 10,
                radiusKm: nil,
                categoryId: selectedCategory
            )

            switch result {
            case .success(let (feedResponse, categories, stores, tutorials, combos)):
                self.feedSections = feedResponse.sections
                self.categories = categories
                self.stores = stores
                self.tutorials = tutorials
                self.combos = combos
                let summary = feedResponse.sections
                    .map { "[\($0.sectionId): \($0.products.count)]" }
                    .joined(separator: ", ")
                print("📦 Feed: \(feedResponse.sections.count) secciones → \(summary)")
                let diagnosticsSummary = feedResponse.sectionDiagnostics
                    .map { diagnostic -> String in
                        let reason = diagnostic.reason ?? "-"
                        let before = diagnostic.totalBeforeDedup.map(String.init) ?? "-"
                        let after = diagnostic.totalAfterDedup.map(String.init) ?? "-"
                        return
                            "[\(diagnostic.sectionId): \(diagnostic.status), reason=\(reason), before=\(before), after=\(after)]"
                    }
                    .joined(separator: ", ")
                print(
                    "🧪 Feed diagnostics (\(feedResponse.sectionDiagnostics.count)) → \(diagnosticsSummary)"
                )

                // Populate legacy arrays from sections for backward compatibility
                self.populateLegacyArraysFromSections()

                self.isLoading = false
                self.hasLoaded = true
                self.state = .success

                // Load "Pide de nuevo" items in background when user is authenticated
                if let jwt = AuthManager.shared.getAccessToken() {
                    Task {
                        self.reorderItems = await self.repository.fetchRecentOrderItems(jwt: jwt)
                        print("🔄 [Feed] Pide de nuevo: \(self.reorderItems.count) items loaded")
                    }
                }

            case .failure(let error):
                self.isLoading = false
                let nsError = error as NSError
                let isNetworkError = nsError.domain == NSURLErrorDomain
                let errorMessage =
                    isNetworkError
                    ? "No hay conexión a internet"
                    : "Error al cargar el feed: \(error.localizedDescription)"
                self.state = .error(errorMessage)
            }
        }
    }

    /// Populate legacy product arrays from the new feed sections for backward compatibility
    private func populateLegacyArraysFromSections() {
        // "para_ti" section goes to featuredProducts
        if let paraTiSection = feedSections.first(where: {
            $0.sectionId == FeedSectionType.paraTi.rawValue
        }) {
            self.featuredProducts = paraTiSection.products
        }

        // "populares_cerca" section goes to popularProducts
        if let popularesSection = feedSections.first(where: {
            $0.sectionId == FeedSectionType.popularesCerca.rawValue
        }) {
            self.popularProducts = popularesSection.products
        }

        // "te_podria_gustar" section goes to recentProducts
        if let recentSection = feedSections.first(where: {
            $0.sectionId == FeedSectionType.tePodriagustar.rawValue
        }) {
            self.recentProducts = recentSection.products
        }
    }

    func loadMoreProducts() {
        guard !isLoadingMore, hasNextPage, let cursor = currentCursor else { return }

        isLoadingMore = true

        Task {
            let result = await repository.fetchMoreProducts(
                after: cursor, radiusKm: nil, categoryId: selectedCategory)

            self.isLoadingMore = false

            switch result {
            case .success(let (products, pageInfo)):
                self.recentProducts.append(contentsOf: products)
                self.currentCursor = pageInfo.endCursor
                self.hasNextPage = pageInfo.hasNextPage

            case .failure:
                break
            }
        }
    }

    func loadMoreIfNeeded(currentItem: FeedProduct?) {
        guard let currentItem = currentItem else {
            loadMoreProducts()
            return
        }

        guard recentProducts.count >= 3 else {
            loadMoreProducts()
            return
        }

        let thresholdIndex = recentProducts.count - 3
        if let currentIndex = recentProducts.firstIndex(where: { $0.id == currentItem.id }),
            currentIndex >= thresholdIndex
        {
            loadMoreProducts()
        }
    }

    func dismissTutorials() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showTutorials = false
        }
        TutorialsHelper.hideTutorials()
    }

    func resetTutorials() {
        TutorialsHelper.showTutorials()
        withAnimation(.easeInOut(duration: 0.3)) {
            showTutorials = true
        }
    }

    func selectCategory(_ category: FeedCategory?) {
        let previousCategory = selectedCategory

        if let category = category {
            selectedCategory = category.isAll ? nil : category.id
        } else {
            selectedCategory = nil
        }

        // Recargar el feed solo si la categoría cambió
        if previousCategory != selectedCategory {
            hasLoaded = false
            loadFeed(isRefreshing: false)
        }
    }

    // MARK: - Section Helpers

    /// Get a specific section by its type
    func getSection(_ type: FeedSectionType) -> FeedSection? {
        return feedSections.first(where: { $0.sectionId == type.rawValue })
    }

    /// Get all sections except "para_ti" (which is rendered separately at the top)
    var horizontalSections: [FeedSection] {
        return feedSections.filter { $0.sectionId != FeedSectionType.paraTi.rawValue }
    }

    /// Get "para_ti" section (featured products with large cards)
    var paraTiSection: FeedSection? {
        return getSection(.paraTi)
    }

    // MARK: - Filtered Data (for category filtering)

    var filteredFeaturedProducts: [FeedProduct] {
        guard let category = selectedCategory else {
            return featuredProducts
        }
        return featuredProducts.filter { $0.categoryId == category || $0.categoryName == category }
    }

    var filteredRecentProducts: [FeedProduct] {
        guard let category = selectedCategory else {
            return recentProducts
        }
        return recentProducts.filter { $0.categoryId == category || $0.categoryName == category }
    }

    var filteredPopularProducts: [FeedProduct] {
        let maxDistanceKm = 3.0  // 2-3km maximo

        var filtered = popularProducts

        // Primero filtrar por distancia
        filtered = filtered.filter { product in
            guard let distance = product.distanceKm else { return true }  // Allow products without distance
            return distance <= maxDistanceKm
        }

        // Luego filtrar por categoría si hay una seleccionada
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryId == category || $0.categoryName == category }
        }

        return filtered
    }

    var filteredStores: [FeedStore] {
        return stores
    }

    /// Filter products in a section by selected category
    func filteredProducts(for section: FeedSection) -> [FeedProduct] {
        guard let category = selectedCategory else {
            return section.products
        }
        return section.products.filter { $0.categoryId == category || $0.categoryName == category }
    }
}
