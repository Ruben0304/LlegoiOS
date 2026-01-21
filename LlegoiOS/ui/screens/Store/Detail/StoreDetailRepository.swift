import Foundation
import Apollo

class StoreDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch complete branch/store details by ID
    func fetchBranchDetail(id: String, completion: @escaping @Sendable (Result<BranchDetailGraphQL, Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetBranchDetailQuery(id: id),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Branch Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let branch = graphQLResult.data?.branch else {
                    print("⚠️ No branch detail data received for ID: \(id)")
                    completion(.failure(NSError(domain: "BranchDetail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Branch not found"])))
                    return
                }

                // Map GraphQL branch detail to our model
                let branchDetail = BranchDetailGraphQL(
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
                    facilities: branch.facilities,
                    createdAt: branch.createdAt,
                    socialMedia: nil // Will be loaded separately
                )

                print("✅ Fetched branch detail for ID: \(id)")
                completion(.success(branchDetail))

            case .failure(let error):
                print("❌ Network Error (Branch Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Fetch business details including social media
    func fetchBusinessDetail(id: String, completion: @escaping @Sendable (Result<BusinessDetailGraphQL, Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetBusinessDetailQuery(id: id),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Business Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let business = graphQLResult.data?.business else {
                    print("⚠️ No business detail data received for ID: \(id)")
                    completion(.failure(NSError(domain: "BusinessDetail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Business not found"])))
                    return
                }

                let businessDetail = BusinessDetailGraphQL(
                    id: business.id,
                    name: business.name,
                    socialMedia: Self.parseSocialMedia(business.socialMedia),
                    avatarUrl: business.avatarUrl,
                    coverUrl: business.avatarUrl
                )

                print("✅ Fetched business detail for ID: \(id)")
                completion(.success(businessDetail))

            case .failure(let error):
                print("❌ Network Error (Business Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // Fetch sibling branches (branches of the same business)
    func fetchSiblingBranches(businessId: String, completion: @escaping @Sendable (Result<[BranchGraphQL], Error>) -> Void) {
        let client = apolloClient
        
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue
            
            client.fetch(
                query: LlegoAPI.GetBranchesQuery(
                    first: 100,
                    after: .none,
                    businessId: .some(businessId),
                    tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                    radiusKm: .none,
                    jwt: jwt.map { .some($0) } ?? .none
                ),
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Sibling Branches):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let data = graphQLResult.data else {
                    print("⚠️ No sibling branches data received")
                    completion(.success([]))
                    return
                }

                let mappedBranches = data.branches.edges.map { edge in
                    BranchGraphQL(
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
                        createdAt: edge.node.createdAt
                    )
                }

                print("✅ Fetched \(mappedBranches.count) sibling branches for business \(businessId)")
                completion(.success(mappedBranches))

            case .failure(let error):
                print("❌ Network Error (Sibling Branches): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        }
    }

    // Fetch products for a specific branch
    func fetchBranchProducts(branchId: String, limit: Int = 10, completion: @escaping @Sendable (Result<[StoreProductGraphQL], Error>) -> Void) {
        let client = apolloClient
        
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue
            
            client.fetch(
                query: LlegoAPI.GetProductsQuery(
                    first: Int32(limit),
                    after: .none,
                    branchId: .some(branchId),
                    categoryId: .none,
                    availableOnly: .some(true),
                    branchTipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                    radiusKm: .none,
                    jwt: jwt.map { .some($0) } ?? .none
                ),
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Branch Products):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    print("⚠️ No products data received for branch \(branchId)")
                    completion(.success([]))
                    return
                }

                // Limit to first 'limit' products
                let limitedProducts = Array(products.edges.prefix(limit))

                let mappedProducts = limitedProducts.map { edge in
                    StoreProductGraphQL(
                        id: edge.node.id,
                        branchId: edge.node.branchId,
                        name: edge.node.name,
                        price: edge.node.price,
                        currency: edge.node.currency,
                        imageUrl: edge.node.imageUrl,
                        availability: edge.node.availability,
                        createdAt: edge.node.createdAt
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
    }

    private static func parseSocialMedia(_ json: LlegoAPI.JSON?) -> [String: String]? {
        guard let jsonString = json,
              let data = jsonString.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = object as? [String: String] else {
            return nil
        }

        return dict
    }
}

// MARK: - Models
// BranchGraphQL and CoordinatesGraphQL are defined in Store/StoreModels.swift

// Model to represent complete GraphQL Branch details
struct BranchDetailGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String?
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let avatarUrl: String?
    let coverUrl: String?
    let deliveryRadius: Double?
    let facilities: [String]?
    let createdAt: String
    let socialMedia: [String: String]?
}

// Model to represent GraphQL Business details
struct BusinessDetailGraphQL: Identifiable, Sendable {
    let id: String
    let name: String
    let socialMedia: [String: String]?
    let avatarUrl: String?
    let coverUrl: String?
}

// Model to represent GraphQL Product for store detail (to avoid conflict with ProductRepository)
struct StoreProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
}
