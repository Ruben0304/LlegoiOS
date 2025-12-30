import Foundation
import Apollo

class SearchRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Search products by query
    func searchProducts(query: String, completion: @escaping @Sendable (Result<[SearchProductGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.SearchProductsQuery(query: query),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (searchProducts):")
                    let messages = errors.map { $0.localizedDescription }
                    messages.forEach { msg in
                        print("  - \(msg)")
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
                        image: product.image,
                        availability: product.availability,
                        createdAt: product.createdAt
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

    // Search branches (stores) by query
    func searchBranches(query: String, completion: @escaping @Sendable (Result<[SearchBranchGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.SearchBranchesQuery(
                query: query,
                limit: .none,
                useVectorSearch: .none
            ),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (searchBranches):")
                    let messages = errors.map { $0.localizedDescription }
                    messages.forEach { msg in
                        print("  - \(msg)")
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
