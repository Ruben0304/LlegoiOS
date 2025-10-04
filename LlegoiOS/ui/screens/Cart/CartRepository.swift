import Foundation
import Apollo

class CartRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
     private let cartManager = CartManager.shared

    // MARK: - GraphQL Fetching

    /// Obtener datos completos de los productos en el carrito desde GraphQL
    func fetchCartProducts(completion: @escaping @Sendable (Result<[CartProductGraphQL], Error>) -> Void) {
        let localItems = cartManager.localItems

        print("🔍 CartRepository: Fetching cart products...")
        print("📋 Local items in cart: \(localItems.count)")
        localItems.forEach { print("   - Product ID: '\($0.productId)' qty: \($0.quantity)") }

        // Si no hay items, retornar array vacío
        guard !localItems.isEmpty else {
            print("⚠️ CartRepository: No items in cart, returning empty array")
            completion(.success([]))
            return
        }

        let productIds = localItems.map { $0.productId }
        print("🔎 Querying GraphQL for product IDs: \(productIds)")

        apolloClient.fetch(
            query: LlegoAPI.GetCartProductsQuery(ids: productIds),
            cachePolicy: .fetchIgnoringCacheData // Siempre datos frescos para el carrito
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors fetching cart products:")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors"])))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                // Mapear GraphQL products y combinar con cantidades locales
                let mappedProducts = products.compactMap { product -> CartProductGraphQL? in
                    guard let localItem = localItems.first(where: { $0.productId == product.id }) else {
                        return nil
                    }

                    return CartProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.image,
                        availability: product.availability,
                        quantity: localItem.quantity
                    )
                }

                print("✅ Fetched \(mappedProducts.count) cart products from GraphQL")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network error fetching cart products: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

/// Item del carrito guardado localmente (solo id + cantidad)
struct CartItemLocal: Codable, Sendable {
    let productId: String
    var quantity: Int
}

/// Producto completo del carrito (datos GraphQL + cantidad local)
struct CartProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
    let quantity: Int // Cantidad del carrito (desde local storage)
}
