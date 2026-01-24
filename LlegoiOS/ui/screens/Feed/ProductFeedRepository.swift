import Foundation
import Apollo

// MARK: - Feed Data Models

struct FeedCategory: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let icon: String
    let isAll: Bool
    let isFeatured: Bool
    
    init(id: String, name: String, icon: String, isAll: Bool = false, isFeatured: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isAll = isAll
        self.isFeatured = isFeatured
    }
}

struct FeedStore: Identifiable, Hashable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let avatarUrl: String?
    let coverUrl: String?
    let address: String?
    let distanceKm: Double?
}

struct FeedProduct: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let distanceKm: Double?
    let branchId: String
    let branchName: String
    let branchAvatarUrl: String?
    let businessName: String
    let categoryId: String?
    let categoryName: String?
    
    var formattedPrice: String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "CUP": symbol = "₱"
        default: symbol = currency
        }
        return String(format: "\(symbol)%.2f", price)
    }
    
    var formattedDistance: String? {
        guard let distance = distanceKm else { return nil }
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        }
        return String(format: "%.1f km", distance)
    }
}

struct FeedData: Sendable {
    let categories: [FeedCategory]
    let stores: [FeedStore]
    let featuredProducts: [FeedProduct]
    let recentProducts: [FeedProduct]
    let popularProducts: [FeedProduct]
    let hasMoreProducts: Bool
    let nextCursor: String?
}

// MARK: - Repository

@MainActor
class ProductFeedRepository {
    
    func fetchFeedData(radiusKm: Double? = nil, categoryId: String? = nil) async -> Result<FeedData, Error> {
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue
        
        // Fetch sequentially to avoid concurrency issues
        let categories = await fetchCategories(branchType: branchType)
        // Para stores: filtrar por categoryId si existe (backend debe soportar esto)
        let stores = await fetchStores(branchType: branchType, radiusKm: radiusKm, categoryId: categoryId, jwt: jwt)
        // Featured products: no requiere distancia específica
        let (featuredProducts, _) = await fetchProducts(first: 6, branchType: branchType, categoryId: categoryId, radiusKm: radiusKm, jwt: jwt)
        // Recent products: sin límite de distancia
        let (recentProducts, recentPageInfo) = await fetchProducts(first: 10, branchType: branchType, categoryId: categoryId, radiusKm: radiusKm, jwt: jwt)
        // Popular products: máximo 3km de distancia
        let (popularProducts, _) = await fetchProducts(first: 8, branchType: branchType, categoryId: categoryId, radiusKm: 3.0, jwt: jwt)
        
        let feedData = FeedData(
            categories: categories,
            stores: stores,
            featuredProducts: featuredProducts,
            recentProducts: recentProducts,
            popularProducts: popularProducts,
            hasMoreProducts: recentPageInfo.hasNextPage,
            nextCursor: recentPageInfo.endCursor
        )
        
        return .success(feedData)
    }
    
    func fetchMoreProducts(after cursor: String, radiusKm: Double? = nil, categoryId: String? = nil) async -> Result<([FeedProduct], PageInfo), Error> {
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue
        
        let (products, pageInfo) = await fetchProducts(first: 10, after: cursor, branchType: branchType, categoryId: categoryId, radiusKm: radiusKm, jwt: jwt)
        return .success((products, pageInfo))
    }
    
    // MARK: - Private fetch methods using fetchIgnoringCacheData to avoid double callback
    
    private func fetchCategories(branchType: String) async -> [FeedCategory] {
        let query = LlegoAPI.GetProductCategoriesQuery(branchType: .some(branchType))
        
        return await withCheckedContinuation { continuation in
            ApolloClientManager.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                var cats: [FeedCategory] = []
                cats.append(FeedCategory(id: "all", name: "Todos", icon: "square.grid.2x2", isAll: true, isFeatured: false))
                
                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for cat in data.productCategories {
                        cats.append(FeedCategory(id: cat.id, name: cat.name, icon: cat.iconIos, isAll: false, isFeatured: false))
                    }
                }
                continuation.resume(returning: cats)
            }
        }
    }
    
    private func fetchStores(branchType: String, radiusKm: Double?, categoryId: String?, jwt: String?) async -> [FeedStore] {
        let query = LlegoAPI.GetBranchesQuery(
            first: 15,
            after: .none,
            businessId: .none,
            tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            productCategoryId: categoryId.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )
        
        return await withCheckedContinuation { continuation in
            ApolloClientManager.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                var stores: [FeedStore] = []
                
                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for edge in data.branches.edges {
                        stores.append(FeedStore(
                            id: edge.node.id,
                            businessId: edge.node.businessId,
                            name: edge.node.name,
                            avatarUrl: edge.node.avatarUrl,
                            coverUrl: edge.node.coverUrl,
                            address: edge.node.address,
                            distanceKm: edge.node.distanceKm
                        ))
                    }
                }
                continuation.resume(returning: stores)
            }
        }
    }
    
    private func fetchProducts(first: Int, after: String? = nil, branchType: String, categoryId: String?, radiusKm: Double?, jwt: String?) async -> ([FeedProduct], PageInfo) {
        let query = LlegoAPI.GetProductsQuery(
            first: Int32(first),
            after: after.map { .some($0) } ?? .none,
            branchId: .none,
            categoryId: categoryId.map { .some($0) } ?? .none,
            availableOnly: .some(true),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )
        
        return await withCheckedContinuation { continuation in
            ApolloClientManager.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheCompletely) { result in
                var products: [FeedProduct] = []
                var pageInfo = PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil, totalCount: 0)
                
                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for edge in data.products.edges {
                        products.append(FeedProduct(
                            id: edge.node.id,
                            name: edge.node.name,
                            price: edge.node.price,
                            currency: edge.node.currency,
                            imageUrl: edge.node.imageUrl,
                            distanceKm: edge.node.distanceKm,
                            branchId: edge.node.branchId,
                            branchName: edge.node.business?.name ?? "",
                            branchAvatarUrl: edge.node.business?.avatarUrl,
                            businessName: edge.node.business?.name ?? "Tienda",
                            categoryId: edge.node.categoryId,
                            categoryName: edge.node.categoryName
                        ))
                    }
                    pageInfo = PageInfo(
                        hasNextPage: data.products.pageInfo.hasNextPage,
                        hasPreviousPage: data.products.pageInfo.hasPreviousPage,
                        startCursor: data.products.pageInfo.startCursor,
                        endCursor: data.products.pageInfo.endCursor,
                        totalCount: Int(data.products.pageInfo.totalCount)
                    )
                }
                continuation.resume(returning: (products, pageInfo))
            }
        }
    }
}
