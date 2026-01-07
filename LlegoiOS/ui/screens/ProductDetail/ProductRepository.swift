import Foundation
import Apollo

class ProductRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all products from GraphQL
    func fetchProducts(completion: @escaping @Sendable (Result<[ProductListGraphQL], Error>) -> Void) {
        apolloClient.fetch(query: LlegoAPI.GetProductsQuery(
            branchId: .none,
            categoryId: .none,
            availableOnly: .none,
            branchTipo: .none,
            radiusKm: .none,
            jwt: .none
        ), cachePolicy: .returnCacheDataAndFetch) { result in
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
                
                guard let products = graphQLResult.data?.products else {
                    print("⚠️ No products data received")
                    completion(.success([]))
                    return
                }
                
                // Map GraphQL products to our model (list view - optimized)
                let mappedProducts = products.map { product in
                    ProductListGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        price: product.price,
                        currency: product.currency,
                        imageUrl: product.imageUrl,
                        availability: product.availability,
                        createdAt: product.createdAt
                    )
                }
                
                print("✅ Fetched \(mappedProducts.count) products from GraphQL")
                completion(.success(mappedProducts))
                
            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// Model to represent GraphQL Product for list view (optimized)
struct ProductListGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
}
