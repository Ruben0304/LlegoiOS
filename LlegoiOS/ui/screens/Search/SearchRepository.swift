import Foundation
import Apollo

class SearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Search products by query with vector search (with automatic fallback)
    func searchProducts(query: String, limit: Int = 20, useVectorSearch: Bool = true, completion: @escaping @Sendable (Result<[SearchProductGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.SearchProductsQuery(
                query: query,
                limit: .some(Int32(limit)),
                useVectorSearch: .some(useVectorSearch),
                radiusKm: .none,
                jwt: .none
            ),
            cachePolicy: .returnCacheDataAndFetch
        ) { [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (searchProducts):")
                    let messages = errors.map { $0.localizedDescription }
                    messages.forEach { msg in
                        print("  - \(msg)")
                    }

                    // If vector search failed, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        apolloClient.fetch(
                            query: LlegoAPI.SearchProductsQuery(
                                query: query,
                                limit: .some(Int32(limit)),
                                useVectorSearch: .some(false),
                                radiusKm: .none,
                                jwt: .none
                            ),
                            cachePolicy: .returnCacheDataAndFetch
                        ) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed")
                                    let combined = messages.joined(separator: "; ")
                                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "Both searches failed" : combined])))
                                    return
                                }

                                guard let products = fallbackGraphQLResult.data?.searchProducts else {
                                    completion(.success([]))
                                    return
                                }

                                let mappedProducts = products.map { product in
                                    SearchProductGraphQL(
                                        id: product.id,
                                        branchId: product.branchId,
                                        name: product.name,
                                        description: product.description,
                                        weight: product.weight,
                                        price: product.price,
                                        currency: product.currency,
                                        image: product.imageUrl,
                                        availability: product.availability,
                                        createdAt: product.createdAt,
                                        businessName: product.business?.name ?? "Tienda"
                                    )
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

                    let combined = messages.joined(separator: "; ")
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "GraphQL errors occurred" : combined])))
                    return
                }

                guard let products = graphQLResult.data?.searchProducts else {
                    print("⚠️ No products found for query: \(query)")
                    completion(.success([]))
                    return
                }

                // Map GraphQL products to our model
                let mappedProducts = products.map { product in
                    SearchProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: product.business?.name ?? "Tienda"
                    )
                }

                print("✅ Found \(mappedProducts.count) products for query: \(query)")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error (searchProducts): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Search branches (stores) by query with vector search (with automatic fallback)
    func searchBranches(query: String, limit: Int = 20, useVectorSearch: Bool = true, completion: @escaping @Sendable (Result<[SearchBranchGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.SearchBranchesQuery(
                query: query,
                limit: .some(Int32(limit)),
                useVectorSearch: .some(useVectorSearch)
            ),
            cachePolicy: .returnCacheDataAndFetch
        ) { [apolloClient = self.apolloClient] result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (searchBranches):")
                    let messages = errors.map { $0.localizedDescription }
                    messages.forEach { msg in
                        print("  - \(msg)")
                    }

                    // If vector search failed, retry with text search
                    if useVectorSearch {
                        print("⚠️ Vector search failed, falling back to text search...")
                        apolloClient.fetch(
                            query: LlegoAPI.SearchBranchesQuery(
                                query: query,
                                limit: .some(Int32(limit)),
                                useVectorSearch: .some(false)
                            ),
                            cachePolicy: .returnCacheDataAndFetch
                        ) { fallbackResult in
                            switch fallbackResult {
                            case .success(let fallbackGraphQLResult):
                                if let fallbackErrors = fallbackGraphQLResult.errors {
                                    print("❌ Text search also failed")
                                    let combined = messages.joined(separator: "; ")
                                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "Both searches failed" : combined])))
                                    return
                                }

                                guard let branches = fallbackGraphQLResult.data?.searchBranches else {
                                    completion(.success([]))
                                    return
                                }

                                let mappedBranches = branches.map { branch in
                                    SearchBranchGraphQL(
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

                    let combined = messages.joined(separator: "; ")
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: combined.isEmpty ? "GraphQL errors occurred" : combined])))
                    return
                }

                guard let branches = graphQLResult.data?.searchBranches else {
                    print("⚠️ No branches found for query: \(query)")
                    completion(.success([]))
                    return
                }

                // Map GraphQL branches to our model
                let mappedBranches = branches.map { branch in
                    SearchBranchGraphQL(
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
                        createdAt: branch.createdAt
                    )
                }

                print("✅ Found \(mappedBranches.count) branches for query: \(query)")
                completion(.success(mappedBranches))

            case .failure(let error):
                print("❌ Network Error (searchBranches): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Model to represent GraphQL Product for Search
struct SearchProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
    let createdAt: String
    let businessName: String
}

// Model to represent GraphQL Branch (Store) for Search
struct SearchBranchGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let createdAt: String
}
