import Foundation
import Apollo

class HomeRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch home data (products + branches) from GraphQL
    func fetchHomeData(completion: @escaping @Sendable (Result<HomeData, Error>) -> Void) {
        apolloClient.fetch(query: LlegoAPI.GetHomeDataQuery(), cachePolicy: .returnCacheDataAndFetch) { result in
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
                    print("⚠️ No home data received")
                    completion(.success(HomeData(products: [], branches: [])))
                    return
                }

                // Map GraphQL products to our model
                let mappedProducts = data.products.map { product in
                    HomeProductGraphQL(
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
                        createdAt: branch.createdAt
                    )
                }

                print("✅ Fetched \(mappedProducts.count) products and \(mappedBranches.count) branches from GraphQL")
                completion(.success(HomeData(products: mappedProducts, branches: mappedBranches)))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Container for home data
struct HomeData: Sendable {
    let products: [HomeProductGraphQL]
    let branches: [BranchGraphQL]
}

// Model to represent GraphQL Product for Home
struct HomeProductGraphQL: Identifiable, Sendable {
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

// Model to represent GraphQL Branch (Store)
struct BranchGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let createdAt: String
}

// Model for coordinates
struct CoordinatesGraphQL: Sendable {
    let type: String
    let coordinates: [Double]
}
