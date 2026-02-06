//
//  SearchRepository.swift
//  LlegoiOS
//
//  Repositorio para búsqueda de productos y tiendas
//

import Foundation
import Apollo
import MapKit

class SearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    
    // MARK: - Search Products
    @MainActor
    func searchProducts(
        query: String,
        first: Int32 = 20,
        completion: @escaping @Sendable (Result<[Product], Error>) -> Void
    ) {
        print("🌐 SearchRepository - searchProducts() called with query: '\(query)'")

        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        #if DEBUG
        print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente" : "NO presente")")
        #endif

        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue
        print("🏪 SearchRepository - branchType: \(branchType)")

        let searchQuery = LlegoAPI.SearchProductsQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        print("🚀 SearchRepository - Calling apolloClient.fetch() for products...")
        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            print("📡 SearchRepository - Apollo fetch callback received for products")

            switch result {
            case .success(let graphQLResult):
                print("✅ SearchRepository - GraphQL query SUCCESS")

                if let errors = graphQLResult.errors, !errors.isEmpty {
                    print("❌ SearchRepository - GraphQL errors: \(errors.compactMap { $0.message }.joined(separator: ", "))")
                    completion(.failure(NSError(
                        domain: "GraphQL",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Error desconocido"]
                    )))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ SearchRepository - No data in GraphQL result, returning empty array")
                    completion(.success([]))
                    return
                }

                print("📦 SearchRepository - Received \(data.searchProducts.edges.count) product edges")

                let products = data.searchProducts.edges.map { edge -> Product in
                    let node = edge.node
                    let priceFormatted = String(format: "%.2f %@", node.price, node.currency)

                    return Product(
                        id: node.id,
                        name: node.name,
                        shop: node.business?.name ?? "",
                        weight: node.weight,
                        price: priceFormatted,
                        imageUrl: node.imageUrl
                    )
                }

                print("✅ SearchRepository - Mapped to \(products.count) Product objects")
                completion(.success(products))

            case .failure(let error):
                print("❌ SearchRepository - Apollo fetch FAILED: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Search Branches/Stores (con productos anidados)
    @MainActor
    func searchBranches(
        query: String,
        first: Int32 = 20,
        completion: @escaping @Sendable (Result<([StoreWithCoordinates], [String: [ProductGraphQL]]), Error>) -> Void
    ) {
        print("🌐 SearchRepository - searchBranches() called with query: '\(query)'")

        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        #if DEBUG
        print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente" : "NO presente")")
        #endif

        let searchQuery = LlegoAPI.SearchBranchesQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            radiusKm: .none,
            jwt: jwt.map { .some($0) } ?? .none
        )

        print("🚀 SearchRepository - Calling apolloClient.fetch() for branches...")
        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            print("📡 SearchRepository - Apollo fetch callback received for branches")

            switch result {
            case .success(let graphQLResult):
                print("✅ SearchRepository - GraphQL query SUCCESS")

                if let errors = graphQLResult.errors, !errors.isEmpty {
                    print("❌ SearchRepository - GraphQL errors: \(errors.compactMap { $0.message }.joined(separator: ", "))")
                    completion(.failure(NSError(
                        domain: "GraphQL",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Error desconocido"]
                    )))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ SearchRepository - No data in GraphQL result, returning empty array")
                    completion(.success(([], [:])))
                    return
                }

                print("🏪 SearchRepository - Received \(data.searchBranches.edges.count) branch edges")

                var storeProducts: [String: [ProductGraphQL]] = [:]

                let stores = data.searchBranches.edges.map { edge -> StoreWithCoordinates in
                    let node = edge.node

                    // Mapear productos anidados
                    let products = node.products.map { product in
                        ProductGraphQL(
                            id: product.id,
                            branchId: node.id,
                            name: product.name,
                            price: product.price,
                            currency: product.currency,
                            imageUrl: product.imageUrl,
                            availability: product.availability,
                            createdAt: "",
                            businessName: node.name,
                            distanceKm: nil,
                            categoryId: nil,
                            categoryName: nil
                        )
                    }
                    storeProducts[node.id] = products
                    print("  ├─ Branch '\(node.name)' con \(products.count) productos anidados")

                    // Calcular ETA basado en deliveryRadius
                    let etaMinutes = node.deliveryRadius.map { Int($0 * 5 + 10) } ?? 30

                    return StoreWithCoordinates(
                        id: node.id,
                        name: node.name,
                        etaMinutes: etaMinutes,
                        logoUrl: node.avatarUrl ?? "",
                        bannerUrl: node.coverUrl ?? "",
                        address: node.address ?? "",
                        rating: nil,
                        coordinate: CLLocationCoordinate2D(
                            latitude: node.coordinates.coordinates[1],
                            longitude: node.coordinates.coordinates[0]
                        )
                    )
                }

                print("✅ SearchRepository - Mapped to \(stores.count) Store objects con productos anidados")
                completion(.success((stores, storeProducts)))

            case .failure(let error):
                print("❌ SearchRepository - Apollo fetch FAILED: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
