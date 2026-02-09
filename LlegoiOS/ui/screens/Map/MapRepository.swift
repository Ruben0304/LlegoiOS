import Apollo
import Foundation

class MapRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL
    func fetchBranches(
        businessId: String? = nil, productCategoryId: String? = nil, radiusKm: Double? = nil,
        completion: @escaping @Sendable (Result<[MapBranchGraphQL], Error>) -> Void
    ) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetBranchesQuery(
                first: 100,
                after: .none,
                businessId: businessId.map { .some($0) } ?? .none,
                tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) }
                    ?? .none,
                radiusKm: radiusKm.map { .some($0) } ?? .none,
                productCategoryId: productCategoryId.map { .some($0) } ?? .none,
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
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ No branch data received")
                        completion(.success([]))
                        return
                    }

                    // Map GraphQL branches to our model
                    let mappedBranches = data.branches.edges.map { edge in
                        MapBranchGraphQL(
                            id: edge.node.id,
                            businessId: edge.node.businessId,
                            name: edge.node.name,
                            address: edge.node.address ?? "",
                            coordinates: MapCoordinatesGraphQL(
                                type: edge.node.coordinates.type,
                                coordinates: edge.node.coordinates.coordinates
                            ),
                            phone: edge.node.phone,
                            status: edge.node.status,
                            avatarUrl: edge.node.avatarUrl,
                            coverUrl: edge.node.coverUrl,
                            deliveryRadius: edge.node.deliveryRadius,
                            createdAt: edge.node.createdAt,
                            score: edge.node.score,
                            distanceKm: edge.node.distanceKm
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
    }
}

// MARK: - Models

// Model to represent GraphQL Branch for Map
struct MapBranchGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let coordinates: MapCoordinatesGraphQL
    let phone: String
    let status: String
    let avatarUrl: String?
    let coverUrl: String?
    let deliveryRadius: Double?
    let createdAt: String
    let score: Double
    let distanceKm: Double?
}

// Model for coordinates
struct MapCoordinatesGraphQL: Sendable {
    let type: String
    let coordinates: [Double]
}
