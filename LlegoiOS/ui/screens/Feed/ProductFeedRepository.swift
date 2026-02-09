import Apollo
import Foundation

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
    let branchAddress: String?
    let branchTipos: [String]
    let businessName: String
    let categoryId: String?
    let categoryName: String?
    let availability: Bool
    let score: Double
    let productDescription: String

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

    // Convenience init for backward compatibility (old code paths)
    init(
        id: String, name: String, price: Double, currency: String, imageUrl: String,
        distanceKm: Double?, branchId: String, branchName: String, branchAvatarUrl: String?,
        businessName: String, categoryId: String?, categoryName: String?
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.imageUrl = imageUrl
        self.distanceKm = distanceKm
        self.branchId = branchId
        self.branchName = branchName
        self.branchAvatarUrl = branchAvatarUrl
        self.branchAddress = nil
        self.branchTipos = []
        self.businessName = businessName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.availability = true
        self.score = 0
        self.productDescription = ""
    }

    // Full init with all new fields
    init(
        id: String, name: String, price: Double, currency: String, imageUrl: String,
        distanceKm: Double?, branchId: String, branchName: String, branchAvatarUrl: String?,
        branchAddress: String?, branchTipos: [String], businessName: String, categoryId: String?,
        categoryName: String?, availability: Bool, score: Double, productDescription: String
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.imageUrl = imageUrl
        self.distanceKm = distanceKm
        self.branchId = branchId
        self.branchName = branchName
        self.branchAvatarUrl = branchAvatarUrl
        self.branchAddress = branchAddress
        self.branchTipos = branchTipos
        self.businessName = businessName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.availability = availability
        self.score = score
        self.productDescription = productDescription
    }
}

// MARK: - Feed Section Model

/// Represents a section in the feed with its products
struct FeedSection: Identifiable, Hashable, Sendable {
    let id: String  // sectionId
    let sectionId: String
    let title: String
    let description: String?
    let products: [FeedProduct]
    let totalCount: Int

    init(
        sectionId: String, title: String, description: String?, products: [FeedProduct],
        totalCount: Int
    ) {
        self.id = sectionId
        self.sectionId = sectionId
        self.title = title
        self.description = description
        self.products = products
        self.totalCount = totalCount
    }
}

// MARK: - Section Type Enum

/// Known section types from the backend
enum FeedSectionType: String {
    case paraTi = "para_ti"
    case popularesCerca = "populares_cerca"
    case trending = "trending"
    case basadoBusquedas = "basado_busquedas"
    case nuevosLugaresFavoritos = "nuevos_lugares_favoritos"
    case masFavoriteados = "mas_favoriteados"
    case cercaTi = "cerca_ti"
    case tePodriagustar = "te_podria_gustar"
    case unknown

    init(rawValue: String) {
        switch rawValue {
        case "para_ti": self = .paraTi
        case "populares_cerca": self = .popularesCerca
        case "trending": self = .trending
        case "basado_busquedas": self = .basadoBusquedas
        case "nuevos_lugares_favoritos": self = .nuevosLugaresFavoritos
        case "mas_favoriteados": self = .masFavoriteados
        case "cerca_ti": self = .cercaTi
        case "te_podria_gustar": self = .tePodriagustar
        default: self = .unknown
        }
    }
}

// MARK: - Feed Response

struct FeedResponse: Sendable {
    let sections: [FeedSection]
    let sectionDiagnostics: [FeedSectionDiagnostic]
    let timestamp: String
}

struct FeedSectionDiagnostic: Sendable {
    let sectionId: String
    let title: String
    let status: String
    let reason: String?
    let totalBeforeDedup: Int?
    let totalAfterDedup: Int?
}

// MARK: - Legacy Feed Data (for backward compatibility with categories/stores)

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
    // Request all known feed sections explicitly.
    private let allSections = [
        FeedSectionType.paraTi.rawValue,
        FeedSectionType.popularesCerca.rawValue,
        FeedSectionType.trending.rawValue,
        FeedSectionType.basadoBusquedas.rawValue,
        FeedSectionType.nuevosLugaresFavoritos.rawValue,
        FeedSectionType.masFavoriteados.rawValue,
        FeedSectionType.cercaTi.rawValue,
        FeedSectionType.tePodriagustar.rawValue,
    ]

    // MARK: - Complete Feed API (Single Query Optimization)

    /// Fetch complete feed data (feed sections, categories, stores, tutorials) in a single GraphQL query
    func fetchCompleteFeed(first: Int = 10, radiusKm: Double? = nil, categoryId: String? = nil)
        async -> Result<(FeedResponse, [FeedCategory], [FeedStore], [Tutorial]), Error>
    {
        let jwt = AuthManager.shared.getAccessToken()
        let branchTypeRaw = BranchTypeManager.shared.selectedType.rawValue
        let branchTipo = LlegoAPI.BranchTipo(rawValue: branchTypeRaw)
        print(
            "🧭 [Feed] GetCompleteFeed branchTipo=\(branchTypeRaw), branchTipoEnum=\(branchTipo?.rawValue ?? "nil")"
        )

        return await withCheckedContinuation { continuation in
            let query = LlegoAPI.GetCompleteFeedQuery(
                jwt: jwt.map { .some($0) } ?? .none,
                first: .some(Int32(first)),
                sections: .some(allSections),
                branchTipo: branchTypeRaw,
                branchTipoEnum: branchTipo.map { .some(GraphQLEnum($0)) } ?? .none,
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                categoryId: categoryId.map { .some($0) } ?? .none
            )

            ApolloClientManager.shared.apollo.fetch(
                query: query, cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        // Parse feed sections
                        let sections = data.getFeed.sections.map { section -> FeedSection in
                            let products = section.products.map { product -> FeedProduct in
                                FeedProduct(
                                    id: product.id,
                                    name: product.name,
                                    price: product.price,
                                    currency: product.currency,
                                    imageUrl: product.imageUrl,
                                    distanceKm: nil,
                                    branchId: product.branchId,
                                    branchName: product.branch?.name ?? "",
                                    branchAvatarUrl: nil,
                                    branchAddress: product.branch?.address,
                                    branchTipos: product.branch?.tipos.compactMap { $0.rawValue }
                                        ?? [],
                                    businessName: product.branch?.name ?? "",
                                    categoryId: nil,
                                    categoryName: product.categoryName,
                                    availability: product.availability,
                                    score: product.score,
                                    productDescription: product.description
                                )
                            }

                            return FeedSection(
                                sectionId: section.sectionId,
                                title: section.title,
                                description: section.description,
                                products: products,
                                totalCount: section.totalCount
                            )
                        }

                        let sectionDiagnostics = data.getFeed.sectionDiagnostics.map { diagnostic in
                            FeedSectionDiagnostic(
                                sectionId: diagnostic.sectionId,
                                title: diagnostic.title,
                                status: diagnostic.status,
                                reason: diagnostic.reason,
                                totalBeforeDedup: diagnostic.totalBeforeDedup,
                                totalAfterDedup: diagnostic.totalAfterDedup
                            )
                        }

                        let feedResponse = FeedResponse(
                            sections: sections,
                            sectionDiagnostics: sectionDiagnostics,
                            timestamp: String(describing: data.getFeed.timestamp)
                        )

                        // Parse categories
                        var categories: [FeedCategory] = []
                        categories.append(
                            FeedCategory(
                                id: "all", name: "Todos", icon: "square.grid.2x2", isAll: true,
                                isFeatured: false))
                        for cat in data.productCategories {
                            categories.append(
                                FeedCategory(
                                    id: cat.id, name: cat.name, icon: cat.iconIos, isAll: false,
                                    isFeatured: false))
                        }

                        // Parse stores
                        let stores = data.branches.edges.map { edge -> FeedStore in
                            FeedStore(
                                id: edge.node.id,
                                businessId: edge.node.businessId,
                                name: edge.node.name,
                                avatarUrl: edge.node.avatarUrl,
                                coverUrl: edge.node.coverUrl,
                                address: edge.node.address,
                                distanceKm: edge.node.distanceKm
                            )
                        }

                        // Parse tutorials (sorted by backend order)
                        let tutorials = data.activeTutorials
                            .filter { $0.appTarget.rawValue == "CUSTOMER" }
                            .sorted(by: { $0.order < $1.order })
                            .map { tutorialData -> Tutorial in
                                // Format duration from seconds to mm:ss
                                let minutes = tutorialData.duration / 60
                                let seconds = tutorialData.duration % 60
                                let formattedDuration = String(format: "%d:%02d", minutes, seconds)

                                return Tutorial(
                                    id: tutorialData.id,
                                    title: tutorialData.title,
                                    description: tutorialData.description,
                                    duration: formattedDuration,
                                    thumbnailUrl: tutorialData.thumbnailUrlSigned ?? tutorialData
                                        .thumbnailUrl ?? "",
                                    videoUrl: tutorialData.videoUrlSigned,
                                    category: tutorialData.tags.first
                                )
                            }

                        continuation.resume(
                            returning: .success((feedResponse, categories, stores, tutorials)))
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(
                            returning: .failure(
                                NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: errors.map {
                                            $0.localizedDescription
                                        }.joined(separator: ", ")
                                    ]
                                )))
                    } else {
                        continuation.resume(
                            returning: .failure(
                                NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "No data returned"]
                                )))
                    }

                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - Legacy Feed API (Deprecated - Use fetchCompleteFeed instead)

    /// Fetch the personalized feed using the new GetFeed query
    /// @deprecated Use fetchCompleteFeed() instead for better performance
    func fetchFeed(first: Int = 10, categoryId: String? = nil) async -> Result<FeedResponse, Error>
    {
        let jwt = AuthManager.shared.getAccessToken()
        let branchTypeRaw = BranchTypeManager.shared.selectedType.rawValue
        print("🧭 [Feed] GetFeed branchTipo=\(branchTypeRaw)")

        return await withCheckedContinuation { continuation in
            let query = LlegoAPI.GetFeedQuery(
                jwt: jwt.map { .some($0) } ?? .none,
                first: .some(Int32(first)),
                sections: .some(allSections),
                branchTipo: branchTypeRaw,
                productCategoryId: categoryId.map { .some($0) } ?? .none
            )

            ApolloClientManager.shared.apollo.fetch(
                query: query, cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let data = graphQLResult.data {
                        let sections = data.getFeed.sections.map { section -> FeedSection in
                            let products = section.products.map { product -> FeedProduct in
                                FeedProduct(
                                    id: product.id,
                                    name: product.name,
                                    price: product.price,
                                    currency: product.currency,
                                    imageUrl: product.imageUrl,
                                    distanceKm: nil,  // Not provided in new API
                                    branchId: product.branchId,
                                    branchName: product.branch?.name ?? "",
                                    branchAvatarUrl: nil,  // Not provided in new API
                                    branchAddress: product.branch?.address,
                                    branchTipos: product.branch?.tipos.compactMap { $0.rawValue }
                                        ?? [],
                                    businessName: product.branch?.name ?? "",
                                    categoryId: nil,
                                    categoryName: product.categoryName,
                                    availability: product.availability,
                                    score: product.score,
                                    productDescription: product.description
                                )
                            }

                            return FeedSection(
                                sectionId: section.sectionId,
                                title: section.title,
                                description: section.description,
                                products: products,
                                totalCount: section.totalCount
                            )
                        }

                        let sectionDiagnostics = data.getFeed.sectionDiagnostics.map { diagnostic in
                            FeedSectionDiagnostic(
                                sectionId: diagnostic.sectionId,
                                title: diagnostic.title,
                                status: diagnostic.status,
                                reason: diagnostic.reason,
                                totalBeforeDedup: diagnostic.totalBeforeDedup,
                                totalAfterDedup: diagnostic.totalAfterDedup
                            )
                        }

                        let feedResponse = FeedResponse(
                            sections: sections,
                            sectionDiagnostics: sectionDiagnostics,
                            timestamp: String(describing: data.getFeed.timestamp)
                        )
                        continuation.resume(returning: .success(feedResponse))
                    } else if let errors = graphQLResult.errors, !errors.isEmpty {
                        continuation.resume(
                            returning: .failure(
                                NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: errors.map {
                                            $0.localizedDescription
                                        }.joined(separator: ", ")
                                    ]
                                )))
                    } else {
                        continuation.resume(
                            returning: .failure(
                                NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "No data returned"]
                                )))
                    }

                case .failure(let error):
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - Legacy Methods (for categories, stores, and pagination)

    /// @deprecated Use fetchCompleteFeed() instead for better performance
    /// This method makes 5 sequential queries (categories, stores, 3x products) vs 1 optimized query
    /// Migrating to fetchCompleteFeed() reduces latency by 5x
    @available(
        *, deprecated,
        message:
            "Use fetchCompleteFeed() instead. This method makes 5 sequential queries vs 1, causing 5x higher latency."
    )
    func fetchFeedData(radiusKm: Double? = nil, categoryId: String? = nil) async -> Result<
        FeedData, Error
    > {
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        // Fetch sequentially to avoid concurrency issues
        let categories = await fetchCategories(branchType: branchType)
        // Para stores: filtrar por categoryId si existe (backend debe soportar esto)
        let stores = await fetchStores(
            branchType: branchType, radiusKm: radiusKm, categoryId: categoryId, jwt: jwt)
        // Featured products: no requiere distancia especifica
        let (featuredProducts, _) = await fetchProducts(
            first: 6, branchType: branchType, categoryId: categoryId, radiusKm: radiusKm, jwt: jwt)
        // Recent products: sin limite de distancia
        let (recentProducts, recentPageInfo) = await fetchProducts(
            first: 10, branchType: branchType, categoryId: categoryId, radiusKm: radiusKm, jwt: jwt)
        // Popular products: maximo 3km de distancia
        let (popularProducts, _) = await fetchProducts(
            first: 8, branchType: branchType, categoryId: categoryId, radiusKm: 3.0, jwt: jwt)

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

    /// @deprecated Use fetchCompleteFeed() with pagination instead
    @available(*, deprecated, message: "Use fetchCompleteFeed() with pagination parameters instead")
    func fetchMoreProducts(after cursor: String, radiusKm: Double? = nil, categoryId: String? = nil)
        async -> Result<([FeedProduct], PageInfo), Error>
    {
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        let (products, pageInfo) = await fetchProducts(
            first: 10, after: cursor, branchType: branchType, categoryId: categoryId,
            radiusKm: radiusKm, jwt: jwt)
        return .success((products, pageInfo))
    }

    // MARK: - Categories (still needed for filter chips)

    func fetchCategories(branchType: String) async -> [FeedCategory] {
        let query = LlegoAPI.GetProductCategoriesQuery(branchType: .some(branchType))

        return await withCheckedContinuation { continuation in
            ApolloClientManager.shared.apollo.fetch(
                query: query, cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                var cats: [FeedCategory] = []
                cats.append(
                    FeedCategory(
                        id: "all", name: "Todos", icon: "square.grid.2x2", isAll: true,
                        isFeatured: false))

                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for cat in data.productCategories {
                        cats.append(
                            FeedCategory(
                                id: cat.id, name: cat.name, icon: cat.iconIos, isAll: false,
                                isFeatured: false))
                    }
                }
                continuation.resume(returning: cats)
            }
        }
    }

    // MARK: - Stores (still needed for store section)

    func fetchStores(branchType: String, radiusKm: Double?, categoryId: String?, jwt: String?) async
        -> [FeedStore]
    {
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
            ApolloClientManager.shared.apollo.fetch(
                query: query, cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                var stores: [FeedStore] = []

                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for edge in data.branches.edges {
                        stores.append(
                            FeedStore(
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

    // MARK: - Private fetch methods using fetchIgnoringCacheData to avoid double callback

    private func fetchProducts(
        first: Int, after: String? = nil, branchType: String, categoryId: String?,
        radiusKm: Double?, jwt: String?
    ) async -> ([FeedProduct], PageInfo) {
        let query = LlegoAPI.GetProductsQuery(
            first: Int32(first),
            after: after.map { .some($0) } ?? .none,
            branchId: .none,
            categoryId: categoryId.map { .some($0) } ?? .none,
            availableOnly: .some(true),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) }
                ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        return await withCheckedContinuation { continuation in
            ApolloClientManager.shared.apollo.fetch(
                query: query, cachePolicy: .fetchIgnoringCacheCompletely
            ) { result in
                var products: [FeedProduct] = []
                var pageInfo = PageInfo(
                    hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil,
                    totalCount: 0)

                if case .success(let graphQLResult) = result, let data = graphQLResult.data {
                    for edge in data.products.edges {
                        products.append(
                            FeedProduct(
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
