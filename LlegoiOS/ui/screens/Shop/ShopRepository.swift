import Foundation
import Apollo

class ShopRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch all products from GraphQL
    func fetchProducts(branchId: String? = nil, completion: @escaping @Sendable (Result<[ShopProductGraphQL], Error>) -> Void) {
        let query = LlegoAPI.GetProductsQuery(
            branchId: branchId.map { .some($0) } ?? .none,
            categoryId: .none,
            availableOnly: .none
        )
        apolloClient.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { [apolloClient = self.apolloClient] result in
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

                // Map GraphQL products to our model (list view - optimized)
                let mappedProducts = data.products.map { product in
                    ShopProductGraphQL(
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

                print("✅ Fetched \(mappedProducts.count) products from GraphQL for Shop")
                completion(.success(mappedProducts))

            case .failure(let error):
                print("❌ Network Error: \(error.localizedDescription)")

                // Si es error de red (offline), intentar cargar SOLO desde caché
                if let nsError = error as NSError?,
                   nsError.domain == NSURLErrorDomain &&
                   (nsError.code == NSURLErrorNotConnectedToInternet ||
                    nsError.code == NSURLErrorTimedOut ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorNetworkConnectionLost) {

                    print("🔄 Sin conexión - Intentando cargar productos desde caché...")

                    // Intentar cargar SOLO desde caché (sin red)
                    apolloClient.fetch(query: query, cachePolicy: .returnCacheDataDontFetch) { cacheResult in
                        switch cacheResult {
                        case .success(let graphQLResult):
                            if let data = graphQLResult.data {
                                let mappedProducts = data.products.map { product in
                                    ShopProductGraphQL(
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

                                print("✅ Cargados \(mappedProducts.count) productos desde caché (offline)")
                                completion(.success(mappedProducts))
                            } else {
                                print("⚠️ No hay datos de productos en caché")
                                completion(.success([]))
                            }
                        case .failure:
                            print("❌ No hay productos en caché")
                            completion(.success([]))
                        }
                    }
                } else {
                    // Otros errores (no de red) -> fallar
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Models

// Model to represent GraphQL Product for Shop list view (optimized)
struct ShopProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let createdAt: String
    let businessName: String

    var formattedPrice: String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = ""
        case "EUR": symbol = "€"
        case "CUP": symbol = "₱"
        default: symbol = currency
        }
        return String(format: "%.2f \(symbol == "" ? "US$" : symbol)", price)
    }
}
