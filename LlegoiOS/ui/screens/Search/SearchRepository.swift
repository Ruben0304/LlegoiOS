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
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        
        // Obtener tipo de branch global
        let branchType = BranchTypeManager.shared.selectedType.rawValue
        
        let searchQuery = LlegoAPI.SearchProductsQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
            radiusKm: .none,
            jwt: jwt.map { .some($0) } ?? .none
        )
        
        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    completion(.failure(NSError(
                        domain: "GraphQL",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Error desconocido"]
                    )))
                    return
                }
                
                guard let data = graphQLResult.data else {
                    completion(.success([]))
                    return
                }
                
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
                
                completion(.success(products))
                
            case .failure(let error):
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
        // Obtener JWT si está disponible
        let jwt = AuthManager.shared.getAccessToken()
        
        let searchQuery = LlegoAPI.SearchBranchesQuery(
            query: query,
            first: first,
            after: .none,
            useVectorSearch: .some(true),
            radiusKm: .none,
            jwt: jwt.map { .some($0) } ?? .none
        )
        
        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    completion(.failure(NSError(
                        domain: "GraphQL",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: errors.first?.message ?? "Error desconocido"]
                    )))
                    return
                }
                
                guard let data = graphQLResult.data else {
                    completion(.success([]))
                    return
                }
                
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
                
                completion(.success(stores))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
