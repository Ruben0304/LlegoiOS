import Foundation
import Apollo
import Combine

class StoreListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL
    func fetchBranches(businessId: String? = nil, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetBranchesQuery(
                businessId: businessId.map { .some($0) } ?? .none,
                tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                jwt: jwt.map { .some($0) } ?? .none
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
                    completion(.success([]))
                    return
                }

                // Map GraphQL branches to our model
                let mappedBranches = data.branches.map { branch in
                    BranchGraphQL(
                        id: branch.id,
                        businessId: branch.businessId,
                        name: branch.name,
                        address: branch.address ?? "",
                        coordinates: CoordinatesGraphQL(
                            type: branch.coordinates.type,
                            coordinates: branch.coordinates.coordinates
                        ),
                        phone: branch.phone,
                        status: branch.status,
                        avatarUrl: branch.avatarUrl,
                        coverUrl: branch.coverUrl,
                        deliveryRadius: branch.deliveryRadius,
                        facilities: nil,
                        createdAt: branch.createdAt
                    )
                }

                print("✅ Fetched \(mappedBranches.count) branches from GraphQL")
                completion(.success(mappedBranches))

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
                                let mappedBranches = data.branches.map { branch in
                                    BranchGraphQL(
                                        id: branch.id,
                                        businessId: branch.businessId,
                                        name: branch.name,
                                        address: branch.address ?? "",
                                        coordinates: CoordinatesGraphQL(
                                            type: branch.coordinates.type,
                                            coordinates: branch.coordinates.coordinates
                                        ),
                                        phone: branch.phone,
                                        status: branch.status,
                                        avatarUrl: branch.avatarUrl,
                                        coverUrl: branch.coverUrl,
                                        deliveryRadius: branch.deliveryRadius,
                                        facilities: nil,
                                        createdAt: branch.createdAt
                                    )
                                }

                                print("✅ Cargados \(mappedBranches.count) branches desde caché (offline)")
                                completion(.success(mappedBranches))
                            } else {
                                print("⚠️ No hay branches en caché")
                                completion(.success([]))
                            }
                        case .failure:
                            print("❌ No hay branches en caché")
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

    // Fetch products for a specific branch
    func fetchBranchProducts(branchId: String, limit: Int = 6, completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetProductsQuery(
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

                let mappedProducts = Array(products.prefix(limit)).map { product in
                    ProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: "", // Not available in this context
                        distanceKm: product.distanceKm
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
                                let mappedProducts = Array(products.prefix(limit)).map { product in
                                    ProductGraphQL(
                                        id: product.id,
                                        branchId: product.branchId,
                                        name: product.name,
                                        price: product.price,
                                        currency: product.currency,
                                        imageUrl: product.imageUrl,
                                        availability: product.availability,
                                        createdAt: product.createdAt,
                                        businessName: "", // Not available in this context
                                        distanceKm: product.distanceKm
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
                limit: .some(Int32(limit)),
                useVectorSearch: .some(useVectorSearch),
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Search Errors:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }

                    // If vector search failed, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        let textSearchQuery = LlegoAPI.SearchBranchesQuery(
                            query: query,
                            limit: .some(Int32(limit)),
                            useVectorSearch: .some(false),
                            radiusKm: radiusKm.map { .some($0) } ?? .none,
                            jwt: jwt.map { .some($0) } ?? .none
                        )

                        client.fetch(query: textSearchQuery, cachePolicy: .fetchIgnoringCacheData) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed")
                                    let error = NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Both searches failed"])
                                    completion(.failure(error))
                                    return
                                }

                                guard let data = fallbackGraphQLResult.data else {
                                    print("⚠️ No search results from text search")
                                    completion(.success([]))
                                    return
                                }

                                let mappedBranches = data.searchBranches.map { branch in
                                    BranchGraphQL(
                                        id: branch.id,
                                        businessId: branch.businessId,
                                        name: branch.name,
                                        address: branch.address ?? "",
                                        coordinates: CoordinatesGraphQL(
                                            type: branch.coordinates.type,
                                            coordinates: branch.coordinates.coordinates
                                        ),
                                        phone: branch.phone,
                                        status: branch.status,
                                        avatarUrl: branch.avatarUrl,
                                        coverUrl: branch.coverUrl,
                                        deliveryRadius: branch.deliveryRadius,
                                        facilities: nil,
                                        createdAt: branch.createdAt
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

                // Map search results
                let mappedBranches = data.searchBranches.map { branch in
                    BranchGraphQL(
                        id: branch.id,
                        businessId: branch.businessId,
                        name: branch.name,
                        address: branch.address ?? "",
                        coordinates: CoordinatesGraphQL(
                            type: branch.coordinates.type,
                            coordinates: branch.coordinates.coordinates
                        ),
                        phone: branch.phone,
                        status: branch.status,
                        avatarUrl: branch.avatarUrl,
                        coverUrl: branch.coverUrl,
                        deliveryRadius: branch.deliveryRadius,
                        facilities: nil,
                        createdAt: branch.createdAt
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
