import Foundation
import Apollo

@MainActor
class FavoritesRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let favoritesManager = FavoritesManager.shared

    func fetchFavoriteProducts(completion: @escaping @Sendable (Result<[FavoriteProductGraphQL], Error>) -> Void) {
        let localItems = favoritesManager.localItems

        print("🔍 FavoritesRepository: Fetching favorite products...")
        print("📋 Local items in favorites: \(localItems.count)")

        guard !localItems.isEmpty else {
            print("⚠️ FavoritesRepository: No favorites, returning empty array")
            completion(.success([]))
            return
        }

        let productIds = localItems.map { $0.productId }
        print("🔎 Querying GraphQL for favorite IDs: \(productIds)")

        apolloClient.fetch(
            query: LlegoAPI.GetCartProductsQuery(ids: productIds),
            cachePolicy: .fetchIgnoringCacheData
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors fetching favorites:")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors"])))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                let mappedProducts = products.map { product in
                    FavoriteProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.image,
                        availability: product.availability
                    )
                }

                print("✅ Fetched \(mappedProducts.count) favorite products from GraphQL")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network error fetching favorites: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

struct FavoriteItemLocal: Codable, Sendable {
    let productId: String
}

struct FavoriteProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
}
