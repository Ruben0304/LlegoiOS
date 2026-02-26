import Apollo
import Combine
import Foundation

class ProductListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all products from GraphQL with cursor pagination
    @MainActor func fetchProducts(
        first: Int = 20, after: String? = nil, branchId: String? = nil, categoryId: String? = nil,
        radiusKm: Double? = nil,
        completion:
            @escaping @Sendable (Result<(products: [ProductGraphQL], pageInfo: PageInfo), Error>) ->
            Void
    ) {
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        print(
            "📦 fetchProducts - branchId: \(branchId ?? "nil"), branchType: \(branchType), first: \(first)"
        )

        let query = LlegoAPI.GetProductsQuery(
            first: Int32(first),
            after: after.map { .some($0) } ?? .none,
            branchId: branchId.map { .some($0) } ?? .none,
            categoryId: categoryId.map { .some($0) } ?? .none,
            availableOnly: .none,
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) }
                ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        // Usar política de caché diferente si hay branchId específico
        // Para evitar mostrar datos incorrectos del caché
        let cachePolicy: ApolloCompatCachePolicy =
            branchId != nil ? .fetchIgnoringCacheData : .returnCacheDataAndFetch

        apolloClient.fetchCompat(query: query, cachePolicy: cachePolicy) {
            [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No products data received")
                    let emptyPageInfo = PageInfo(
                        hasNextPage: false, hasPreviousPage: false, startCursor: nil,
                        endCursor: nil, totalCount: 0)
                    completion(.success((products: [], pageInfo: emptyPageInfo)))
                    return
                }

                let mappedProducts = data.products.edges.map { edge in
                    ProductGraphQL(
                        id: edge.node.id,
                        branchId: edge.node.branchId,
                        name: edge.node.name,
                        price: edge.node.price,
                        currency: edge.node.currency,
                        imageUrl: edge.node.imageUrl,
                        availability: edge.node.availability,
                        createdAt: edge.node.createdAt,
                        businessName: edge.node.business?.name ?? "Tienda",
                        distanceKm: edge.node.distanceKm,
                        categoryId: edge.node.categoryId,
                        categoryName: edge.node.category?.name
                    )
                }

                let pageInfo = PageInfo(
                    hasNextPage: data.products.pageInfo.hasNextPage,
                    hasPreviousPage: data.products.pageInfo.hasPreviousPage,
                    startCursor: data.products.pageInfo.startCursor,
                    endCursor: data.products.pageInfo.endCursor,
                    totalCount: Int(data.products.pageInfo.totalCount)
                )

                print(
                    "✅ Fetched \(mappedProducts.count) products from GraphQL for Shop (hasNextPage: \(pageInfo.hasNextPage), totalCount: \(pageInfo.totalCount))"
                )
                completion(.success((products: mappedProducts, pageInfo: pageInfo)))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")

                // Si es error de red (offline), intentar cargar SOLO desde caché
                if let nsError = error as NSError?,
                    nsError.domain == NSURLErrorDomain
                        && (nsError.code == NSURLErrorNotConnectedToInternet
                            || nsError.code == NSURLErrorTimedOut
                            || nsError.code == NSURLErrorCannotConnectToHost
                            || nsError.code == NSURLErrorNetworkConnectionLost)
                {

                    print("🔄 Sin conexión - Intentando cargar productos desde caché...")

                    // Intentar cargar SOLO desde caché (sin red)
                    apolloClient.fetchCompat(query: query, cachePolicy: .returnCacheDataDontFetch) {
                        cacheResult in
                        switch cacheResult {
                        case .success(let graphQLResult):
                            if let data = graphQLResult.data {
                                let mappedProducts = data.products.edges.map { edge in
                                    ProductGraphQL(
                                        id: edge.node.id,
                                        branchId: edge.node.branchId,
                                        name: edge.node.name,
                                        price: edge.node.price,
                                        currency: edge.node.currency,
                                        imageUrl: edge.node.imageUrl,
                                        availability: edge.node.availability,
                                        createdAt: edge.node.createdAt,
                                        businessName: edge.node.business?.name ?? "Tienda",
                                        distanceKm: edge.node.distanceKm,
                                        categoryId: edge.node.categoryId,
                                        categoryName: edge.node.category?.name
                                    )
                                }

                                let pageInfo = PageInfo(
                                    hasNextPage: data.products.pageInfo.hasNextPage,
                                    hasPreviousPage: data.products.pageInfo.hasPreviousPage,
                                    startCursor: data.products.pageInfo.startCursor,
                                    endCursor: data.products.pageInfo.endCursor,
                                    totalCount: Int(data.products.pageInfo.totalCount)
                                )

                                print(
                                    "✅ Cargados \(mappedProducts.count) productos desde caché (offline)"
                                )
                                completion(.success((products: mappedProducts, pageInfo: pageInfo)))
                            } else {
                                print("⚠️ No hay datos de productos en caché")
                                let emptyPageInfo = PageInfo(
                                    hasNextPage: false, hasPreviousPage: false, startCursor: nil,
                                    endCursor: nil, totalCount: 0)
                                completion(.success((products: [], pageInfo: emptyPageInfo)))
                            }
                        case .failure:
                            print("❌ No hay productos en caché")
                            let emptyPageInfo = PageInfo(
                                hasNextPage: false, hasPreviousPage: false, startCursor: nil,
                                endCursor: nil, totalCount: 0)
                            completion(.success((products: [], pageInfo: emptyPageInfo)))
                        }
                    }
                } else {
                    // Otros errores (no de red) -> fallar
                    completion(.failure(error))
                }
            }
        }
    }

    // Search products with vector search (with automatic fallback to text search)
    @MainActor func searchProducts(
        query: String, first: Int = 20, after: String? = nil, branchId: String? = nil,
        categoryId: String? = nil, useVectorSearch: Bool = true, radiusKm: Double? = nil,
        completion:
            @escaping @Sendable (Result<(products: [ProductGraphQL], pageInfo: PageInfo), Error>) ->
            Void
    ) {
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        let searchQuery = LlegoAPI.SearchProductsQuery(
            query: query,
            first: Int32(first),
            after: after.map { .some($0) } ?? .none,
            useVectorSearch: .some(useVectorSearch),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) }
                ?? .none,
            categoryId: categoryId.map { .some($0) } ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        apolloClient.fetchCompat(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) {
            [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Search Errors (Products):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }

                    // Check if it's a rate limit error
                    let isRateLimitError = errors.contains { error in
                        error.localizedDescription.lowercased().contains("rate limit")
                    }

                    if isRateLimitError {
                        print(
                            "⏱️ RATE LIMIT DETECTED - Backend ha excedido el límite de búsquedas por minuto"
                        )
                        print("⏱️ Límite: 10 búsquedas/minuto")
                        print("⏱️ Sugerencia: Espera unos segundos antes de realizar otra búsqueda")
                        print("💡 Recomendación: El usuario debe esperar aproximadamente 1 minuto")

                        completion(
                            .failure(
                                NSError(
                                    domain: "RateLimit",
                                    code: 429,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo."
                                    ]
                                )))
                        return
                    }

                    // If vector search failed and we were using it, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        let textSearchQuery = LlegoAPI.SearchProductsQuery(
                            query: query,
                            first: Int32(first),
                            after: after.map { .some($0) } ?? .none,
                            useVectorSearch: .some(false),
                            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map {
                                .some(GraphQLEnum($0))
                            } ?? .none,
                            categoryId: categoryId.map { .some($0) } ?? .none,
                            radiusKm: radiusKm.map { .some($0) } ?? .none,
                            jwt: jwt.map { .some($0) } ?? .none
                        )

                        apolloClient.fetchCompat(
                            query: textSearchQuery, cachePolicy: .fetchIgnoringCacheData
                        ) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed:")
                                    fallbackErrors.forEach {
                                        print("  - \($0.localizedDescription)")
                                    }

                                    // Check rate limit in fallback too
                                    let isFallbackRateLimit = fallbackErrors.contains { error in
                                        error.localizedDescription.lowercased().contains(
                                            "rate limit")
                                    }

                                    if isFallbackRateLimit {
                                        print("⏱️ RATE LIMIT en text search también")
                                        print(
                                            "💡 El backend está limitando las búsquedas - espera 1 minuto"
                                        )
                                        completion(
                                            .failure(
                                                NSError(
                                                    domain: "RateLimit",
                                                    code: 429,
                                                    userInfo: [
                                                        NSLocalizedDescriptionKey:
                                                            "Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo."
                                                    ]
                                                )))
                                    } else {
                                        completion(
                                            .failure(
                                                NSError(
                                                    domain: "GraphQL", code: -1,
                                                    userInfo: [
                                                        NSLocalizedDescriptionKey:
                                                            "Both vector and text search failed"
                                                    ])))
                                    }
                                    return
                                }

                                guard let data = fallbackGraphQLResult.data else {
                                    print("⚠️ No search results from text search")
                                    let emptyPageInfo = PageInfo(
                                        hasNextPage: false, hasPreviousPage: false,
                                        startCursor: nil, endCursor: nil, totalCount: 0)
                                    completion(.success((products: [], pageInfo: emptyPageInfo)))
                                    return
                                }

                                // Map search results from text search
                                var mappedProducts = data.searchProducts.edges.map { edge in
                                    ProductGraphQL(
                                        id: edge.node.id,
                                        branchId: edge.node.branchId,
                                        name: edge.node.name,
                                        price: edge.node.price,
                                        currency: edge.node.currency,
                                        imageUrl: edge.node.imageUrl,
                                        availability: edge.node.availability,
                                        createdAt: edge.node.createdAt,
                                        businessName: edge.node.business?.name ?? "Tienda",
                                        distanceKm: edge.node.distanceKm,
                                        categoryId: edge.node.categoryId,
                                        categoryName: edge.node.category?.name
                                    )
                                }

                                if let branchId = branchId {
                                    mappedProducts = mappedProducts.filter {
                                        $0.branchId == branchId
                                    }
                                }

                                let pageInfo = PageInfo(
                                    hasNextPage: data.searchProducts.pageInfo.hasNextPage,
                                    hasPreviousPage: data.searchProducts.pageInfo.hasPreviousPage,
                                    startCursor: data.searchProducts.pageInfo.startCursor,
                                    endCursor: data.searchProducts.pageInfo.endCursor,
                                    totalCount: Int(data.searchProducts.pageInfo.totalCount)
                                )

                                print(
                                    "✅ Text search fallback found \(mappedProducts.count) products")
                                completion(.success((products: mappedProducts, pageInfo: pageInfo)))

                            case .failure(let error):
                                print(
                                    "❌ Text search fallback failed: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                        return
                    }

                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "GraphQL search errors occurred"
                                ])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No search results received")
                    let emptyPageInfo = PageInfo(
                        hasNextPage: false, hasPreviousPage: false, startCursor: nil,
                        endCursor: nil, totalCount: 0)
                    completion(.success((products: [], pageInfo: emptyPageInfo)))
                    return
                }

                // Map search results
                var mappedProducts = data.searchProducts.edges.map { edge in
                    ProductGraphQL(
                        id: edge.node.id,
                        branchId: edge.node.branchId,
                        name: edge.node.name,
                        price: edge.node.price,
                        currency: edge.node.currency,
                        imageUrl: edge.node.imageUrl,
                        availability: edge.node.availability,
                        createdAt: edge.node.createdAt,
                        businessName: edge.node.business?.name ?? "Tienda",
                        distanceKm: edge.node.distanceKm,
                        categoryId: edge.node.categoryId,
                        categoryName: edge.node.category?.name
                    )
                }

                // Filter by branchId if specified
                if let branchId = branchId {
                    mappedProducts = mappedProducts.filter { $0.branchId == branchId }
                }

                let pageInfo = PageInfo(
                    hasNextPage: data.searchProducts.pageInfo.hasNextPage,
                    hasPreviousPage: data.searchProducts.pageInfo.hasPreviousPage,
                    startCursor: data.searchProducts.pageInfo.startCursor,
                    endCursor: data.searchProducts.pageInfo.endCursor,
                    totalCount: Int(data.searchProducts.pageInfo.totalCount)
                )

                print(
                    "✅ Found \(mappedProducts.count) products matching '\(query)'"
                        + (branchId != nil ? " for branch \(branchId!)" : ""))
                completion(.success((products: mappedProducts, pageInfo: pageInfo)))

            case .failure(let error):
                print("❌ Search Error (Products): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Fetch product categories for a specific branch type
    @MainActor func fetchProductCategories(
        branchType: String?,
        completion: @escaping @Sendable (Result<[ProductCategoryGraphQL], Error>) -> Void
    ) {
        let query = LlegoAPI.GetProductCategoriesQuery(
            branchType: branchType.map { .some($0) } ?? .none)

        apolloClient.fetchCompat(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors fetching categories:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No categories data received")
                    completion(.success([]))
                    return
                }

                let categories = data.productCategories.map { category in
                    ProductCategoryGraphQL(
                        id: category.id,
                        branchType: category.branchType,
                        name: category.name,
                        iconIos: category.iconIos,
                        iconWeb: category.iconWeb,
                        iconAndroid: category.iconAndroid
                    )
                }

                print(
                    "✅ Fetched \(categories.count) categories for branch type: \(branchType ?? "all")"
                )
                completion(.success(categories))

            case .failure(let error):
                print("❌ Error fetching categories: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Model to represent GraphQL Product Category
struct ProductCategoryGraphQL: Identifiable, Sendable {
    let id: String
    let branchType: String
    let name: String
    let iconIos: String
    let iconWeb: String
    let iconAndroid: String
}

// Model to represent GraphQL Product for Shop list view (optimized)
struct ProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
    let businessName: String
    let businessLogoUrl: String
    let distanceKm: Double?
    let categoryId: String?
    let categoryName: String?

    // Inicializador con valor por defecto para businessLogoUrl (retrocompatibilidad)
    init(
        id: String, branchId: String, name: String, price: Double, currency: String,
        imageUrl: String, availability: Bool, createdAt: String, businessName: String,
        businessLogoUrl: String = "", distanceKm: Double?, categoryId: String?,
        categoryName: String?
    ) {
        self.id = id
        self.branchId = branchId
        self.name = name
        self.price = price
        self.currency = currency
        self.imageUrl = imageUrl
        self.availability = availability
        self.createdAt = createdAt
        self.businessName = businessName
        self.businessLogoUrl = businessLogoUrl
        self.distanceKm = distanceKm
        self.categoryId = categoryId
        self.categoryName = categoryName
    }

    var formattedPrice: String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = ""
        case "EUR": symbol = "€"
        case "CUP": symbol = "CUP"
        default: symbol = currency
        }
        return String(format: "%.2f \(symbol == "" ? "US$" : symbol)", price)
    }

    var formattedDistance: String? {
        guard let distance = distanceKm else { return nil }
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        }
        return String(format: "%.1f km", distance)
    }
}
