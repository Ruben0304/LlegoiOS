import Foundation
import Apollo

class ProductDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // Fetch complete product details by ID
    func fetchProductDetail(id: String, completion: @escaping @Sendable (Result<ProductDetailGraphQL, Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetProductDetailQuery(id: id),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors (Product Detail):")
                    errors.forEach { error in
                        print("  - \(error.localizedDescription)")
                    }
                    completion(.failure(NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "GraphQL errors occurred"])))
                    return
                }

                guard let product = graphQLResult.data?.product else {
                    print("⚠️ No product detail data received for ID: \(id)")
                    completion(.failure(NSError(domain: "ProductDetail", code: -1, userInfo: [NSLocalizedDescriptionKey: "Product not found"])))
                    return
                }

                // Map GraphQL product detail to our model
                let productDetail = ProductDetailGraphQL(
                    id: product.id,
                    branchId: product.branchId,
                    name: product.name,
                    description: product.description,
                    weight: product.weight,
                    price: product.price,
                    currency: product.currency,
                    imageUrl: product.imageUrl,
                    availability: product.availability,
                    categoryId: product.categoryId,
                    createdAt: product.createdAt,
                    businessName: product.business?.name ?? "Tienda"
                )

                print("✅ Fetched product detail for ID: \(id)")
                print("📦 PRODUCT DETAIL DATA:")
                print("  - ID: \(productDetail.id)")
                print("  - Name: \(productDetail.name)")
                print("  - Business: \(productDetail.businessName)")
                print("  - Description: \(productDetail.description)")
                print("  - Weight: \(productDetail.weight)")
                print("  - Price: \(productDetail.price)")
                print("  - Currency: \(productDetail.currency)")
                print("  - ImageURL: \(productDetail.imageUrl)")
                print("  - BranchID: \(productDetail.branchId)")
                print("  - Availability: \(productDetail.availability)")
                print("  - CategoryID: \(productDetail.categoryId ?? "nil")")
                print("  - CreatedAt: \(productDetail.createdAt)")
                completion(.success(productDetail))

            case .failure(let error):
                print("❌ Network Error (Product Detail): \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

// Model to represent complete GraphQL Product details
struct ProductDetailGraphQL: Identifiable, Sendable, Equatable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let imageUrl: String
    let availability: Bool
    let categoryId: String?
    let createdAt: String
    let businessName: String
}
