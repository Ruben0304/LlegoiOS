import Foundation
import Apollo

class MapRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL
    func fetchBranches(businessId: String? = nil, radiusKm: Double? = nil, completion: @escaping @Sendable (Result<[MapBranchGraphQL], Error>) -> Void) {
        // Capturar apolloClient antes del Task para evitar data races
        let client = apolloClient

        // Capturar valores del Main Actor en el contexto principal
        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetBranchesQuery(
                businessId: businessId.map { .some($0) } ?? .none,
                tipo: LlegoAPI.BranchTipo(rawValue: branchType).map { .some(GraphQLEnum($0)) } ?? .none,
                radiusKm: radiusKm.map { .some($0) } ?? .none,
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
                        completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ No branch data received")
                        completion(.success([]))
                        return
                    }

                    // Map GraphQL branches to our model
                    let mappedBranches = data.branches.map { branch in
                        MapBranchGraphQL(
                            id: branch.id,
                            businessId: branch.businessId,
                            name: branch.name,
                            address: branch.address ?? "",
                            coordinates: MapCoordinatesGraphQL(
                                type: branch.coordinates.type,
                                coordinates: branch.coordinates.coordinates
                            ),
                            phone: branch.phone,
                            status: branch.status,
                            avatarUrl: branch.avatarUrl,
                            coverUrl: branch.coverUrl,
                            deliveryRadius: branch.deliveryRadius,
                            createdAt: branch.createdAt,
                            score: branch.score,
                            distanceKm: branch.distanceKm
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
