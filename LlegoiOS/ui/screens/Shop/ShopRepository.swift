import Foundation
import Apollo
import Combine

class ShopRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all products from GraphQL
    @MainActor func fetchProducts(branchId: String? = nil, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<[ShopProductGraphQL], Error>) -> Void) {
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        let query = LlegoAPI.GetProductsQuery(
            branchId: branchId.map { .some($0) } ?? .none,
            categoryId: .none,
            availableOnly: .none,
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )
        apolloClient.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No products data received")
                    completion(.success([]))
                    return
                }

                let mappedProducts = data.products.map { product in
                    ShopProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: product.business?.name ?? "Tienda",
                        distanceKm: product.distanceKm
                    )
                }

                print("✅ Fetched \(mappedProducts.count) products from GraphQL for Shop")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")

                // Si es error de red (offline), intentar cargar SOLO desde caché
                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorNotConnectedToInternet ||
                    nsError.code == NSURLErrorTimedOut ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorNetworkConnectionLost) {

                    print("🔄 Sin conexión - Intentando cargar productos desde caché...")

                    // Intentar cargar SOLO desde caché (sin red)
                    apolloClient.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { cacheResult in
                        switch cacheResult {
                        case .success(let graphQLResult):
                            if let data = graphQLResult.data {
                                let mappedProducts = data.products.map { product in
                                    ShopProductGraphQL(
                                        id: product.id,
                                        branchId: product.branchId,
                                        name: product.name,
                                        price: product.price,
                                        currency: product.currency,
                                        imageUrl: product.imageUrl,
                                        availability: product.availability,
                                        createdAt: product.createdAt,
                                        businessName: product.business?.name ?? "Tienda",
                                        distanceKm: product.distanceKm
                                    )
                                }

                                print("✅ Cargados \(mappedProducts.count) productos desde caché (offline)")
                                completion(.success(mappedProducts))
                            } else {
                                print("⚠️ No hay datos de productos en caché")
                                completion(.success([]))
                            }
                        case .failure:
                            print("❌ No hay productos en caché")
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

    // Search products with vector search (with automatic fallback to text search)
    @MainActor func searchProducts(query: String, branchId: String? = nil, limit: Int = 10, useVectorSearch: Bool = true, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<[ShopProductGraphQL], Error>) -> Void) {
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        let searchQuery = LlegoAPI.SearchProductsQuery(
            query: query,
            limit: .some(Int32(limit)),
            useVectorSearch: .some(useVectorSearch),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: radiusKm.map { .some($0) } ?? .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Search Errors (Products):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }

                    // If vector search failed and we were using it, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        let textSearchQuery = LlegoAPI.SearchProductsQuery(
                            query: query,
                            limit: .some(Int32(limit)),
                            useVectorSearch: .some(false),
                            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                            radiusKm: radiusKm.map { .some($0) } ?? .none,
                            jwt: jwt.map { .some($0) } ?? .none
                        )

                        apolloClient.fetch(query: textSearchQuery, cachePolicy: .fetchIgnoringCacheData) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed:")
                                    fallbackErrors.forEach { print("  - \($0.localizedDescription)") }
                                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Both vector and text search failed"])))
                                    return
                                }

                                guard let data = fallbackGraphQLResult.data else {
                                    print("⚠️ No search results from text search")
                                    completion(.success([]))
                                    return
                                }

                                // Map search results from text search
                                var mappedProducts = data.searchProducts.map { product in
                                    ShopProductGraphQL(
                                        id: product.id,
                                        branchId: product.branchId,
                                        name: product.name,
                                        price: product.price,
                                        currency: product.currency,
                                        imageUrl: product.imageUrl,
                                        availability: product.availability,
                                        createdAt: product.createdAt,
                                        businessName: product.business?.name ?? "Tienda",
                                        distanceKm: product.distanceKm
                                    )
                                }

                                if let branchId = branchId {
                                    mappedProducts = mappedProducts.filter { $0.branchId == branchId }
                                }

                                print("✅ Text search fallback found \(mappedProducts.count) products")
                                completion(.success(mappedProducts))

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
                var mappedProducts = data.searchProducts.map { product in
                    ShopProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: product.business?.name ?? "Tienda",
                        distanceKm: product.distanceKm
                    )
                }

                // Filter by branchId if specified
                if let branchId = branchId {
                    mappedProducts = mappedProducts.filter { $0.branchId == branchId }
                }

                print("✅ Found \(mappedProducts.count) products matching '\(query)'" + (branchId != nil ? " for branch \(branchId!)" : ""))
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Search Error (Products): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Model to represent GraphQL Product for Shop list view (optimized)
struct ShopProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
    let businessName: String
    let distanceKm: Double?

    var formattedPrice: String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = ""
        case "EUR": symbol = "€"
        case "CUP": symbol = "₱"
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
