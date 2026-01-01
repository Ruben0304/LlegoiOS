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
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt,
                        businessName: product.business?.name ?? "Tienda"
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
                        avatarUrl: branch.avatarUrl,
                        coverUrl: branch.coverUrl,
                        deliveryRadius: branch.deliveryRadius,
                        facilities: nil,
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
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
    let businessName: String
}

// Model to represent GraphQL Branch (Store)
struct BranchGraphQL: Identifiable, Sendable {
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

    // Constructor con valores por defecto para compatibilidad con HomeData
    init(
        id: String,
        businessId: String,
        name: String,
        address: String? = nil,
        coordinates: CoordinatesGraphQL,
        phone: String,
        status: String,
        avatarUrl: String? = nil,
        coverUrl: String? = nil,
        deliveryRadius: Double? = nil,
        facilities: [String]? = nil,
        createdAt: String
    ) {
        self.id = id
        self.businessId = businessId
        self.name = name
        self.address = address
        self.coordinates = coordinates
        self.phone = phone
        self.status = status
        self.avatarUrl = avatarUrl
        self.coverUrl = coverUrl
        self.deliveryRadius = deliveryRadius
        self.facilities = facilities
        self.createdAt = createdAt
    }
}

// Model for coordinates
struct CoordinatesGraphQL: Sendable {
    let type: String
    let coordinates: [Double]

    var latitude: Double {
        // GeoJSON format: [lng, lat]
        coordinates.count > 1 ? coordinates[1] : 0.0
    }

    var longitude: Double {
        // GeoJSON format: [lng, lat]
        coordinates.count > 0 ? coordinates[0] : 0.0
    }
}
