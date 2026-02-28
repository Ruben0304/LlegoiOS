import Apollo
import Foundation

final class ProductDetailRepository: @unchecked Sendable {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Helper para obtener JWT de manera concurrency-safe
    private func getJWT() async -> String? {
        await MainActor.run {
            AuthManager.shared.getAccessToken()
        }
    }

    // Fetch complete product details by ID
    func fetchProductDetail(
        id: String, completion: @escaping @Sendable (Result<ProductDetailGraphQL, Error>) -> Void
    ) {
        Task {
            // Obtener JWT de manera concurrency-safe
            let jwt = await getJWT()

            print("🔍 ProductDetailRepository: Fetching product detail for ID: \(id)")
            print("🔑 JWT available: \(jwt != nil)")

            let query = LlegoAPI.GetProductDetailQuery(
                id: id,
                jwt: jwt.map { .some($0) } ?? .none
            )

            apolloClient.fetchCompat(
                query: query,
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    // Log any GraphQL errors
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (Product Detail):")
                        errors.forEach { error in
                            print("  - \(error.localizedDescription)")
                            if let extensions = error.extensions {
                                print("    Extensions: \(extensions)")
                            }
                        }
                        // Continue processing if we have data despite errors
                        if graphQLResult.data?.product == nil {
                            completion(
                                .failure(
                                    NSError(
                                        domain: "GraphQL", code: -1,
                                        userInfo: [
                                            NSLocalizedDescriptionKey: "GraphQL errors occurred"
                                        ])))
                            return
                        }
                    }

                    guard let product = graphQLResult.data?.product else {
                        print("⚠️ No product detail data received for ID: \(id)")
                        completion(
                            .failure(
                                NSError(
                                    domain: "ProductDetail", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Product not found"])))
                        return
                    }

                    // Log variant data from GraphQL response
                    print("📦 GRAPHQL RESPONSE DATA:")
                    print("  - Product ID: \(product.id)")
                    print("  - Product Name: \(product.name)")

                    let variantListIds: [String]? = product.variantListIds
                    let variantLists: [VariantList]? = product.variantLists.map { list in
                        VariantList(
                            id: list.id,
                            name: list.name,
                            description: list.description,
                            options: list.options.map { option in
                                VariantOption(
                                    id: option.id,
                                    name: option.name,
                                    priceAdjustment: Decimal(option.priceAdjustment)
                                )
                            }
                        )
                    }
                    print("  - variantListIds from GraphQL: \(variantListIds ?? [])")
                    print("  - variantLists from GraphQL: \(variantLists?.count ?? 0) lists")

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
                        businessName: product.branch?.name ?? product.business?.name ?? "Tienda",
                        businessLogoUrl: product.branch?.avatarUrl ?? product.business?.avatarUrl,
                        variantListIds: variantListIds,
                        variantLists: variantLists
                    )

                    print("✅ Fetched product detail for ID: \(id)")
                    print("📦 FINAL PRODUCT DETAIL DATA:")
                    print("  - ID: \(productDetail.id)")
                    print("  - Name: \(productDetail.name)")
                    print("  - Business: \(productDetail.businessName)")
                    print("  - Price: \(productDetail.price) \(productDetail.currency)")
                    print("  - VariantListIds: \(productDetail.variantListIds?.count ?? 0) IDs")
                    print("  - Variant Lists: \(productDetail.variantLists?.count ?? 0) lists")

                    if let lists = productDetail.variantLists {
                        for (index, list) in lists.enumerated() {
                            print(
                                "    - List \(index): \(list.name) (\(list.options.count) options)")
                        }
                    }

                    completion(.success(productDetail))

                case .failure(let error):
                    print("❌ Network Error (Product Detail): \(error.localizedDescription)")
                    completion(.failure(error))
                }
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
    let businessLogoUrl: String?
    let variantListIds: [String]?
    let variantLists: [VariantList]?
}
