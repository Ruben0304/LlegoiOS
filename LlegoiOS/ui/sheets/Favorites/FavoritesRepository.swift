import Foundation
import Apollo

@MainActor
class FavoritesRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let favoritesManager = FavoritesManager.shared
    private let authManager = AuthManager.shared

    func fetchFavoriteProducts(completion: @escaping @Sendable (Result<[FavoriteProductGraphQL], Error>) -> Void) {
        let localItems = favoritesManager.localItems

        print("🔍 FavoritesRepository: Fetching favorite products...")
        print("📋 Local items in favorites: \(localItems.count)")

        guard !localItems.isEmpty else {
            print("⚠️ FavoritesRepository: No favorites, returning empty array")
            completion(.success([]))
            return
        }

        let productIds = localItems.reduce(into: (ids: [String](), seen: Set<String>())) {
            partial, item in
            if partial.seen.insert(item.productId).inserted {
                partial.ids.append(item.productId)
            }
        }.ids
        let jwt = authManager.getAccessToken()
        print("🔎 Querying GraphQL for favorite IDs: \(productIds)")

        apolloClient.fetchCompat(
            query: LlegoAPI.GetProductsByIdsQuery(
                ids: productIds,
                jwt: jwt.map { .some($0) } ?? .none
            ),
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

                let data = graphQLResult.data?.productsByIds ?? []
                guard !data.isEmpty else {
                    completion(.success([]))
                    return
                }

                let productsById = Dictionary(uniqueKeysWithValues: data.map { ($0.id, $0) })
                let mappedProducts: [FavoriteProductGraphQL] = localItems.compactMap {
                    localItem -> FavoriteProductGraphQL? in
                    guard let node = productsById[localItem.productId] else {
                        return nil
                    }

                    return FavoriteProductGraphQL(
                        id: node.id,
                        branchId: node.branchId,
                        name: node.name,
                        weight: node.weight,
                        price: node.price,
                        currency: node.currency,
                        image: node.imageUrlMuyBaja,
                        availability: node.availability
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
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
}
