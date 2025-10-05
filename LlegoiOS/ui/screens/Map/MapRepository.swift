import Foundation
import Apollo

class MapRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all branches from GraphQL
    func fetchBranches(completion: @escaping @Sendable (Result<[MapBranchGraphQL], Error>) -> Void) {
        apolloClient.fetch(query: LlegoAPI.GetBranchesQuery(), cachePolicy: .returnCacheDataAndFetch) { result in
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
                        address: branch.address,
                        coordinates: MapCoordinatesGraphQL(
                            type: branch.coordinates.type,
                            coordinates: branch.coordinates.coordinates
                        ),
                        phone: branch.phone,
                        status: branch.status,
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
    let createdAt: String
}

// Model for coordinates
struct MapCoordinatesGraphQL: Sendable {
    let type: String
    let coordinates: [Double]
}
