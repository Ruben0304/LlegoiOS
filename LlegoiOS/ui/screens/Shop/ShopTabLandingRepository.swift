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

    // Fetch products for a specific branch
    func fetchBranchProducts(branchId: String, limit: Int = 6, completion: @escaping @Sendable (Result<[ShopProductGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetProductsQuery(
                branchId: .some(branchId),
                categoryId: .none,
                availableOnly: .some(true)
            ),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
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
                    ShopProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: "" // Not available in this context
                    )
                }

                print("✅ Fetched \(mappedProducts.count) products for branch \(branchId)")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error (Branch Products): \(error.localizedDescription)")
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
// BranchGraphQL and CoordinatesGraphQL are defined in HomeRepository.swift
// ShopProductGraphQL is defined in ShopRepository.swift
