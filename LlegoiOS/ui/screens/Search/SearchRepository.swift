//
//  SearchRepository.swift
//  LlegoiOS
//
//  Repositorio para búsqueda de productos y tiendas
//

import Foundation
import Apollo

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
        print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente (\(jwt!.prefix(20))...)" : "NO presente")")

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
    
    // MARK: - Search Branches/Stores
    @MainActor
    func searchBranches(
        query: String,
        first: Int32 = 20,
        completion: @escaping @Sendable (Result<[Store], Error>) -> Void
    ) {
        print("🌐 SearchRepository - searchBranches() called with query: '\(query)'")

        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente (\(jwt!.prefix(20))...)" : "NO presente")")

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
                    completion(.success([]))
                    return
                }

                print("🏪 SearchRepository - Received \(data.searchBranches.edges.count) branch edges")

                let stores = data.searchBranches.edges.map { edge -> Store in
                    let node = edge.node

                    return Store(
                        id: node.id,
                        name: node.name,
                        address: node.address ?? "",
                        etaMinutes: 30,
                        logoUrl: node.avatarUrl ?? "",
                        bannerUrl: node.coverUrl ?? "",
                        rating: nil
                    )
                }

                print("✅ SearchRepository - Mapped to \(stores.count) Store objects")
                completion(.success(stores))

            case .failure(let error):
                print("❌ SearchRepository - Apollo fetch FAILED: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
