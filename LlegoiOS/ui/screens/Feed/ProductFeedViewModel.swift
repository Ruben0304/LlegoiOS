import Foundation
import SwiftUI
import Combine

enum ProductFeedViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ProductFeedViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var state: ProductFeedViewState = .idle
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false

    // Data
    @Published var categories: [FeedCategory] = []
    @Published var stores: [FeedStore] = []
    @Published var featuredProducts: [FeedProduct] = []
    @Published var recentProducts: [FeedProduct] = []
    @Published var popularProducts: [FeedProduct] = []
    @Published var promotions: [Promotion] = []

    // Filters
    @Published var selectedCategory: String? = nil

    // Pagination
    @Published var hasNextPage: Bool = false
    @Published var currentCursor: String? = nil

    // Tutorials visibility
    @Published var showTutorials: Bool = true

    // Sample tutorials
    @Published var tutorials: [Tutorial] = [
        Tutorial(
            id: "1",
            title: "Cómo hacer tu primer pedido",
            description: "Aprende a navegar la app y realizar tu primera compra",
            duration: "3:45",
            thumbnailUrl: "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400&h=300&fit=crop",
            videoUrl: "https://example.com/video1.mp4",
            category: "Primeros pasos"
        ),
        Tutorial(
            id: "2",
            title: "Métodos de pago disponibles",
            description: "Conoce todas las formas de pagar en Llego",
            duration: "2:30",
            thumbnailUrl: "https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=400&h=300&fit=crop",
            videoUrl: "https://example.com/video2.mp4",
            category: "Pagos"
        ),
        Tutorial(
            id: "3",
            title: "Seguimiento de pedidos",
            description: "Rastrea tu pedido en tiempo real",
            duration: "4:15",
            thumbnailUrl: "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=400&h=300&fit=crop",
            videoUrl: "https://example.com/video3.mp4",
            category: "Entregas"
        )
    ]

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
            .dropFirst() // Ignore initial value
            .sink { [weak self] _ in
                guard let self = self else { return }
                print("🔄 ProductFeedViewModel - Branch type changed, reloading feed")
                self.loadFeed(isRefreshing: true)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadFeed(isRefreshing: Bool = false) {
        if hasLoaded && !isRefreshing {
            return
        }
        
        if isRefreshing {
            currentCursor = nil
            hasNextPage = false
            hasLoaded = false
        }
        
        if !isRefreshing {
            isLoading = true
            state = .loading
        }
        
        Task {
            let result = await repository.fetchFeedData(radiusKm: nil)
            
            switch result {
            case .success(let feedData):
                self.categories = feedData.categories
                self.stores = feedData.stores
                self.featuredProducts = feedData.featuredProducts
                self.recentProducts = feedData.recentProducts
                self.popularProducts = feedData.popularProducts
                self.promotions = Promotion.samples // TODO: Replace with API data
                self.hasNextPage = feedData.hasMoreProducts
                self.currentCursor = feedData.nextCursor
                self.isLoading = false
                self.hasLoaded = true
                self.state = .success
                
            case .failure(let error):
                self.isLoading = false
                let nsError = error as NSError
                let isNetworkError = nsError.domain == NSURLErrorDomain
                let errorMessage = isNetworkError
                    ? "No hay conexión a internet"
                    : "Error al cargar el feed: \(error.localizedDescription)"
                self.state = .error(errorMessage)
            }
        }
    }
    
    func loadMoreProducts() {
        guard !isLoadingMore, hasNextPage, let cursor = currentCursor else { return }
        
        isLoadingMore = true
        
        Task {
            let result = await repository.fetchMoreProducts(after: cursor, radiusKm: nil)
            
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
           currentIndex >= thresholdIndex {
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
        if let category = category {
            selectedCategory = category.isAll ? nil : category.name
        } else {
            selectedCategory = nil
        }
    }
    
    // MARK: - Filtered Data
    
    var filteredFeaturedProducts: [FeedProduct] {
        return featuredProducts
    }
    
    var filteredRecentProducts: [FeedProduct] {
        return recentProducts
    }
    
    var filteredPopularProducts: [FeedProduct] {
        return popularProducts
    }
}
