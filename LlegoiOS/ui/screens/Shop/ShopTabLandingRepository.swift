import Foundation
import Apollo

class ShopTabLandingRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL
    func fetchBranches(businessId: String? = nil, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void) {
        let query = LlegoAPI.GetBranchesQuery(businessId: businessId.map { .some($0) } ?? .none)

        apolloClient.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
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
                        address: branch.address,
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
                completion(.failure(error))
            }
        }
    }

    // Search branches by query
    func searchBranches(query: String, limit: Int = 10, useVectorSearch: Bool = true, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void) {
        let searchQuery = LlegoAPI.SearchBranchesQuery(
            query: query,
            limit: .some(Int32(limit)),
            useVectorSearch: .some(useVectorSearch)
        )

        apolloClient.fetch(query: searchQuery, cachePolicy: .fetchIgnoringCacheData) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Search Errors:")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
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
                        address: branch.address,
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

// MARK: - Models
// BranchGraphQL and CoordinatesGraphQL are defined in HomeRepository.swift and shared across the app
