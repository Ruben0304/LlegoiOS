import Foundation
import Apollo

class ShopRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all products from GraphQL
    func fetchProducts(completion: @escaping @Sendable (Result<[ShopProductGraphQL], Error>) -> Void) {
        let query = LlegoAPI.GetProductsQuery(
            branchId: .none,
            categoryId: .none,
            availableOnly: .none
        )
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
                    print("⚠️ No products data received")
                    completion(.success([]))
                    return
                }

                // Map GraphQL products to our model
                let mappedProducts = data.products.map { product in
                    ShopProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.image,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        categoryId: product.categoryId,
                        createdAt: product.createdAt
                    )
                }

                print("✅ Fetched \(mappedProducts.count) products from GraphQL for Shop")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Model to represent GraphQL Product for Shop
struct ShopProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let imageUrl: String
    let availability: Bool
    let categoryId: String?
    let createdAt: String
}
