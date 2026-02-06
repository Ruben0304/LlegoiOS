import Foundation
import Apollo
import Combine

class StoreListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL with cursor pagination
    func fetchBranches(first: Int = 20, after: String? = nil, businessId: String? = nil, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<(branches: [BranchGraphQL], pageInfo: PageInfo), Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetBranchesQuery(
                first: Int32(first),
                after: after.map { .some($0) } ?? .none,
                businessId: businessId.map { .some($0) } ?? .none,
                tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                productCategoryId: .none,
                jwt: jwt.map { .some($0) } ?? .none,
                productsLimit: .some(4)
            )

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    let error = NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])
                    completion(.failure(error))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No branches data received")
                    let emptyPageInfo = PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil, totalCount: 0)
                    completion(.success((branches: [], pageInfo: emptyPageInfo)))
                    return
                }

                // Map GraphQL branches to our model (with nested products)
                let mappedBranches = data.branches.edges.map { edge in
                    // Map nested products
                    let mappedProducts = edge.node.products.map { product in
                        BranchProductGraphQL(
                            id: product.id,
                            name: product.name,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.imageUrl
                        )
                    }

                    return BranchGraphQL(
                        id: edge.node.id,
                        businessId: edge.node.businessId,
                        name: edge.node.name,
                        address: edge.node.address ?? "",
                        coordinates: CoordinatesGraphQL(
                            type: edge.node.coordinates.type,
                            coordinates: edge.node.coordinates.coordinates
                        ),
                        phone: edge.node.phone,
                        status: edge.node.status,
                        avatarUrl: edge.node.avatarUrl,
                        coverUrl: edge.node.coverUrl,
                        deliveryRadius: edge.node.deliveryRadius,
                        facilities: nil,
                        createdAt: edge.node.createdAt,
                        products: mappedProducts
                    )
                }

                let pageInfo = PageInfo(
                    hasNextPage: data.branches.pageInfo.hasNextPage,
                    hasPreviousPage: data.branches.pageInfo.hasPreviousPage,
                    startCursor: data.branches.pageInfo.startCursor,
                    endCursor: data.branches.pageInfo.endCursor,
                    totalCount: Int(data.branches.pageInfo.totalCount)
                )

                print("✅ Fetched \(mappedBranches.count) branches with nested products (hasNextPage: \(pageInfo.hasNextPage), totalCount: \(pageInfo.totalCount))")
                completion(.success((branches: mappedBranches, pageInfo: pageInfo)))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")

                // Si es error de red (offline), intentar cargar SOLO desde caché
                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorNotConnectedToInternet ||
                    nsError.code == NSURLErrorTimedOut ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorNetworkConnectionLost) {

                    print("🔄 Sin conexión - Intentando cargar branches desde caché...")

                    // Intentar cargar SOLO desde caché (sin red)
                    client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { cacheResult in
                        switch cacheResult {
                        case .success(let graphQLResult):
                            if let data = graphQLResult.data {
                                let mappedBranches = data.branches.edges.map { edge in
                                    // Map nested products
                                    let mappedProducts = edge.node.products.map { product in
                                        BranchProductGraphQL(
                                            id: product.id,
                                            name: product.name,
                                            price: product.price,
                                            currency: product.currency,
                                            imageUrl: product.imageUrl
                                        )
                                    }

                                    return BranchGraphQL(
                                        id: edge.node.id,
                                        businessId: edge.node.businessId,
                                        name: edge.node.name,
                                        address: edge.node.address ?? "",
                                        coordinates: CoordinatesGraphQL(
                                            type: edge.node.coordinates.type,
                                            coordinates: edge.node.coordinates.coordinates
                                        ),
                                        phone: edge.node.phone,
                                        status: edge.node.status,
                                        avatarUrl: edge.node.avatarUrl,
                                        coverUrl: edge.node.coverUrl,
                                        deliveryRadius: edge.node.deliveryRadius,
                                        facilities: nil,
                                        createdAt: edge.node.createdAt,
                                        products: mappedProducts
                                    )
                                }

                                let pageInfo = PageInfo(
                                    hasNextPage: data.branches.pageInfo.hasNextPage,
                                    hasPreviousPage: data.branches.pageInfo.hasPreviousPage,
                                    startCursor: data.branches.pageInfo.startCursor,
                                    endCursor: data.branches.pageInfo.endCursor,
                                    totalCount: Int(data.branches.pageInfo.totalCount)
                                )

                                print("✅ Cargados \(mappedBranches.count) branches desde caché (offline)")
                                completion(.success((branches: mappedBranches, pageInfo: pageInfo)))
                            } else {
                                print("⚠️ No hay branches en caché")
                                let emptyPageInfo = PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil, totalCount: 0)
                                completion(.success((branches: [], pageInfo: emptyPageInfo)))
                            }
                        case .failure:
                            print("❌ No hay branches en caché")
                            let emptyPageInfo = PageInfo(hasNextPage: false, hasPreviousPage: false, startCursor: nil, endCursor: nil, totalCount: 0)
                            completion(.success((branches: [], pageInfo: emptyPageInfo)))
                        }
                    }
                } else {
                    // Otros errores (no de red) -> fallar
                    completion(.failure(error))
                }
            }
        }
        }
    }

    // Fetch products for a specific branch
    func fetchBranchProducts(branchId: String, limit: Int = 6, completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetProductsQuery(
                first: Int32(limit),
                after: .none,
                branchId: .some(branchId),
                categoryId: .none,
                availableOnly: .some(true),
                branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                radiusKm: .none,
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Branch Products):")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1)))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                let mappedProducts = Array(products.edges.prefix(limit)).map { edge in
                    ProductGraphQL(
                        id: edge.node.id,
                        branchId: edge.node.branchId,
                        name: edge.node.name,
                        price: edge.node.price,
                        currency: edge.node.currency,
                        imageUrl: edge.node.imageUrl,
                        availability: edge.node.availability,
                        createdAt: edge.node.createdAt,
                        businessName: edge.node.business?.name ?? "",
                        distanceKm: edge.node.distanceKm,
                        categoryId: edge.node.categoryId,
                        categoryName: edge.node.category?.name
                    )
                }

                print("✅ Fetched \(mappedProducts.count) products for branch \(branchId)")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error (Branch Products): \(error.localizedDescription)")

                // Si es error de red (offline), intentar cargar SOLO desde caché
                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorNotConnectedToInternet ||
                    nsError.code == NSURLErrorTimedOut ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorNetworkConnectionLost) {

                    print("🔄 Sin conexión - Intentando cargar productos de \(branchId) desde caché...")

                    // Intentar cargar SOLO desde caché (sin red)
                    client.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { cacheResult in
                        switch cacheResult {
                        case .success(let graphQLResult):
                            if let products = graphQLResult.data?.products {
                                let mappedProducts = Array(products.edges.prefix(limit)).map { edge in
                                    ProductGraphQL(
                                        id: edge.node.id,
                                        branchId: edge.node.branchId,
                                        name: edge.node.name,
                                        price: edge.node.price,
                                        currency: edge.node.currency,
                                        imageUrl: edge.node.imageUrl,
                                        availability: edge.node.availability,
                                        createdAt: edge.node.createdAt,
                                        businessName: edge.node.business?.name ?? "",
                                        distanceKm: edge.node.distanceKm,
                                        categoryId: edge.node.categoryId,
                                        categoryName: edge.node.category?.name
                                    )
                                }

                                print("✅ Cargados \(mappedProducts.count) productos de \(branchId) desde caché (offline)")
                                completion(.success(mappedProducts))
                            } else {
                                print("⚠️ No hay productos de \(branchId) en caché")
                                completion(.success([]))
                            }
                        case .failure:
                            print("❌ No hay productos de \(branchId) en caché")
                            completion(.success([]))
                        }
                    }
                } else {
                    // Otros errores (no de red) -> fallar
                    completion(.failure(error))
                }
            }
        }
        }
    }

    // Search branches by query (with automatic fallback to text search)
    func searchBranches(query: String, limit: Int = 10, useVectorSearch: Bool = true, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()

            let searchQuery = LlegoAPI.SearchBranchesQuery(
                query: query,
                first: Int32(limit),
                after: .none,
                useVectorSearch: .some(useVectorSearch),
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Search Errors (Branches):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }

                    // Check if it's a rate limit error
                    let isRateLimitError = errors.contains { error in
                        error.localizedDescription.lowercased().contains("rate limit")
                    }

                    if isRateLimitError {
                        print("⏱️ RATE LIMIT DETECTED - Backend ha excedido el límite de búsquedas por minuto")
                        print("⏱️ Límite: 10 búsquedas/minuto")
                        print("⏱️ Sugerencia: Espera unos segundos antes de realizar otra búsqueda")
                        print("💡 Recomendación: El usuario debe esperar aproximadamente 1 minuto")
                        
                        completion(.failure(NSError(
                            domain: "RateLimit",
                            code: 429,
                            userInfo: [NSLocalizedDescriptionKey: "Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo."]
                        )))
                        return
                    }

                    // If vector search failed, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        let textSearchQuery = LlegoAPI.SearchBranchesQuery(
                            query: query,
                            first: Int32(limit),
                            after: .none,
                            useVectorSearch: .some(false),
                            radiusKm: radiusKm.map { .some($0) } ?? .none,
                            jwt: jwt.map { .some($0) } ?? .none
                        )

                        client.fetch(query: textSearchQuery, cachePolicy: .fetchIgnoringCacheData) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed:")
                                    fallbackErrors.forEach { print("  - \($0.localizedDescription)") }
                                    
                                    // Check rate limit in fallback too
                                    let isFallbackRateLimit = fallbackErrors.contains { error in
                                        error.localizedDescription.lowercased().contains("rate limit")
                                    }
                                    
                                    if isFallbackRateLimit {
                                        print("⏱️ RATE LIMIT en text search también")
                                        print("💡 El backend está limitando las búsquedas - espera 1 minuto")
                                        completion(.failure(NSError(
                                            domain: "RateLimit",
                                            code: 429,
                                            userInfo: [NSLocalizedDescriptionKey: "Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo."]
                                        )))
                                    } else {
                                        let error = NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Both searches failed"])
                                        completion(.failure(error))
                                    }
                                    return
                                }

                                guard let data = fallbackGraphQLResult.data else {
                                    print("⚠️ No search results from text search")
                                    completion(.success([]))
                                    return
                                }

                                let mappedBranches = data.searchBranches.edges.map { edge in
                                    // Map nested products (fallback text search)
                                    let mappedProducts = edge.node.products.map { product in
                                        BranchProductGraphQL(
                                            id: product.id,
                                            name: product.name,
                                            price: product.price,
                                            currency: product.currency,
                                            imageUrl: product.imageUrl
                                        )
                                    }

                                    return BranchGraphQL(
                                        id: edge.node.id,
                                        businessId: edge.node.businessId,
                                        name: edge.node.name,
                                        address: edge.node.address ?? "",
                                        coordinates: CoordinatesGraphQL(
                                            type: edge.node.coordinates.type,
                                            coordinates: edge.node.coordinates.coordinates
                                        ),
                                        phone: edge.node.phone,
                                        status: edge.node.status,
                                        avatarUrl: edge.node.avatarUrl,
                                        coverUrl: edge.node.coverUrl,
                                        deliveryRadius: edge.node.deliveryRadius,
                                        facilities: nil,
                                        createdAt: edge.node.createdAt,
                                        products: mappedProducts
                                    )
                                }

                                print("✅ Text search fallback found \(mappedBranches.count) branches")
                                completion(.success(mappedBranches))

                            case .failure(let error):
                                print("❌ Text search fallback failed: \(error.localizedDescription)")
                                completion(.failure(error))
                            }
                        }
                        return
                    }

                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL search errors occurred"])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No search results received")
                    completion(.success([]))
                    return
                }

                // Map search results with nested products
                let mappedBranches = data.searchBranches.edges.map { edge in
                    // Map nested products
                    let mappedProducts = edge.node.products.map { product in
                        BranchProductGraphQL(
                            id: product.id,
                            name: product.name,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.imageUrl
                        )
                    }

                    return BranchGraphQL(
                        id: edge.node.id,
                        businessId: edge.node.businessId,
                        name: edge.node.name,
                        address: edge.node.address ?? "",
                        coordinates: CoordinatesGraphQL(
                            type: edge.node.coordinates.type,
                            coordinates: edge.node.coordinates.coordinates
                        ),
                        phone: edge.node.phone,
                        status: edge.node.status,
                        avatarUrl: edge.node.avatarUrl,
                        coverUrl: edge.node.coverUrl,
                        deliveryRadius: edge.node.deliveryRadius,
                        facilities: nil,
                        createdAt: edge.node.createdAt,
                        products: mappedProducts
                    )
                }

                print("✅ Found \(mappedBranches.count) branches matching '\(query)'")
                completion(.success(mappedBranches))

            case .failure(let error):
                print("❌ Search Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        }
    }
}

// MARK: - Models
// BranchGraphQL and CoordinatesGraphQL are defined in Store/StoreModels.swift
// ProductGraphQL is defined in ProductListRepository.swift
