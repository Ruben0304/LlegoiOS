import Apollo
import Combine
import Foundation
import UIKit

@MainActor
class CartRepository {
    private let apolloClient = ApolloClientManager.shared.apollo
    private let cartManager = CartManager.shared
    private let authManager = AuthManager.shared

    // MARK: - GraphQL Fetching

    /// Obtener datos completos de los productos en el carrito desde GraphQL
    func fetchCartProducts(
        completion: @escaping @Sendable (Result<[CartProductGraphQL], Error>) -> Void
    ) {
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

        let productIds = Array(Set(localItems.map { $0.productId }))
        print("🔎 Querying GraphQL for product IDs: \(productIds)")

        apolloClient.fetchCompat(
            query: LlegoAPI.GetCartProductsQuery(
                first: Int32(100),
                after: .none,
                ids: productIds
            ),
            cachePolicy: .fetchIgnoringCacheData  // Siempre datos frescos para el carrito
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors fetching cart products:")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(
                        .failure(
                            NSError(
                                domain: "GraphQL", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "GraphQL errors"])))
                    return
                }

                guard let data = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                // Mapear GraphQL products y combinar con cantidades locales.
                // Soporta múltiples líneas para el mismo productId con variantes distintas.
                let productsById = Dictionary(
                    uniqueKeysWithValues: data.edges.map { ($0.node.id, $0.node) })
                let mappedProducts = localItems.compactMap { localItem -> CartProductGraphQL? in
                    guard let productNode = productsById[localItem.productId] else {
                        print(
                            "⚠️ CartRepository: Product \(localItem.productId) no longer available in backend response"
                        )
                        return nil
                    }

                    let selected = localItem.selectedVariants
                    let computedUnit = NSDecimalNumber(
                        decimal: computeFinalUnitPrice(
                            base: Decimal(productNode.price), selected: selected)
                    ).doubleValue
                    let resolvedBase = localItem.basePrice ?? productNode.price
                    let resolvedUnit = localItem.finalUnitPrice ?? computedUnit
                    let resolvedTotal = resolvedUnit * Double(localItem.quantity)

                    return CartProductGraphQL(
                        id: localItem.cartItemId,
                        cartItemId: localItem.cartItemId,
                        productId: productNode.id,
                        comboGroupId: localItem.comboGroupId,
                        comboId: localItem.comboId,
                        comboName: localItem.comboName,
                        comboComponentSlotId: localItem.comboComponentSlotId,
                        comboComponentSlotName: localItem.comboComponentSlotName,
                        comboComponentOrder: localItem.comboComponentOrder,
                        branchId: productNode.branchId,
                        name: productNode.name,
                        description: productNode.description,
                        weight: productNode.weight,
                        basePrice: resolvedBase,
                        finalUnitPrice: resolvedUnit,
                        finalTotalPrice: resolvedTotal,
                        currency: productNode.currency,
                        image: productNode.imageUrl,
                        availability: productNode.availability,
                        quantity: localItem.quantity,
                        businessName: productNode.business?.name ?? "Tienda",
                        selectedVariants: selected
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

    // MARK: - Delivery Fee Estimation

    /// Estimar el costo de envío para una sucursal
    func estimateDeliveryFee(
        branchId: String,
        completion: @escaping @Sendable (Result<DeliveryFeeEstimate, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            guard let jwt = authManager.getAccessToken() else {
                print("❌ CartRepository: No JWT available for delivery fee estimation")
                completion(
                    .failure(
                        NSError(
                            domain: "CartRepository",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"]
                        )))
                return
            }

            print("🚚 CartRepository: Estimating delivery fee for branch \(branchId)...")

            client.fetchCompat(
                query: LlegoAPI.EstimateDeliveryFeeQuery(
                    branchId: branchId,
                    jwt: jwt
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors estimating delivery fee:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        completion(
                            .failure(
                                NSError(
                                    domain: "GraphQL",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: errors.first?
                                            .localizedDescription ?? "Error estimando envío"
                                    ]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data?.estimateDeliveryFee else {
                        print("❌ CartRepository: No delivery fee data returned")
                        completion(
                            .failure(
                                NSError(
                                    domain: "CartRepository",
                                    code: -2,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "No se recibieron datos de envío"
                                    ]
                                )))
                        return
                    }

                    let estimate = DeliveryFeeEstimate(
                        deliveryFee: data.deliveryFee,
                        currency: data.currency,
                        distanceKm: data.distanceKm,
                        zoneName: data.zoneName,
                        branchId: data.branchId,
                        branchName: data.branchName
                    )

                    print(
                        "✅ Delivery fee estimated: \(estimate.deliveryFee) \(estimate.currency) (distance: \(estimate.distanceKm) km, zone: \(estimate.zoneName ?? "N/A"))"
                    )
                    completion(.success(estimate))

                case .failure(let error):
                    print("❌ Network error estimating delivery fee: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - AI Suggestions

    /// Obtener todos los productos de un branch para enviar a Apple Intelligence
    func fetchAllBranchProducts(
        branchId: String,
        completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = authManager.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            print("🔍 CartRepository: Fetching all products for branch: \(branchId)")

            let query = LlegoAPI.GetProductsQuery(
                first: Int32(100),  // Obtener hasta 100 productos
                after: .none,
                branchId: .some(branchId),
                categoryId: .none,
                availableOnly: .some(true),  // Solo productos disponibles
                branchTipo: LlegoAPI.BranchTipo(rawValue: branchType.uppercased()).map {
                    .some(GraphQLEnum($0))
                } ?? .none,
                radiusKm: .none,
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors fetching branch products:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        completion(
                            .failure(
                                NSError(
                                    domain: "CartRepository",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Error obteniendo productos"
                                    ]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        completion(.success([]))
                        return
                    }

                    let products = data.products.edges.map { edge in
                        ProductGraphQL(
                            id: edge.node.id,
                            branchId: edge.node.branchId,
                            name: edge.node.name,
                            price: edge.node.price,
                            currency: edge.node.currency,
                            imageUrl: edge.node.imageUrl,
                            availability: edge.node.availability,
                            createdAt: edge.node.createdAt,
                            businessName: edge.node.business?.name ?? "Tienda",
                            distanceKm: edge.node.distanceKm,
                            categoryId: edge.node.categoryId,
                            categoryName: edge.node.category?.name
                        )
                    }

                    print("✅ Fetched \(products.count) products from branch")
                    completion(.success(products))

                case .failure(let error):
                    print("❌ Error fetching branch products: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    /// Filtrar productos por IDs devueltos por Apple Intelligence
    func filterProductsByIds(
        productIds: [String],
        allProducts: [ProductGraphQL]
    ) -> [Product] {
        let productsDict = Dictionary(uniqueKeysWithValues: allProducts.map { ($0.id, $0) })

        return productIds.compactMap { id in
            guard let product = productsDict[id] else { return nil }
            return Product(
                id: product.id,
                name: product.name,
                shop: product.businessName,
                shopLogoUrl: "",
                weight: product.currency,
                price: "\(product.currency) \(product.price)",
                imageUrl: product.imageUrl
            )
        }
    }

    // MARK: - Cloud AI Recommendations

    /// Obtener recomendaciones de productos desde la API de Llego en la nube
    /// - Parameters:
    ///   - productIds: IDs de los productos en el carrito
    ///   - limit: Número máximo de recomendaciones (default: 6)
    ///   - completion: Callback con el resultado
    func fetchCloudRecommendations(
        productIds: [String],
        limit: Int = 6,
        completion: @escaping @Sendable (Result<[Product], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = authManager.getAccessToken()

            print("🌐 [CartRepository] Obteniendo recomendaciones desde Llego Cloud")
            print("🌐 [CartRepository] Product IDs: \(productIds)")
            print("🌐 [CartRepository] Limit: \(limit)")

            let query = LlegoAPI.GetProductRecommendationsQuery(
                productIds: productIds,
                limit: Int32(limit),
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ [CartRepository] GraphQL Errors fetching recommendations:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        completion(
                            .failure(
                                NSError(
                                    domain: "CartRepository",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Error obteniendo recomendaciones"
                                    ]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ [CartRepository] No data in recommendations response")
                        completion(.success([]))
                        return
                    }

                    guard let productRecommendations = data.productRecommendations else {
                        print("⚠️ [CartRepository] No productRecommendations in response")
                        completion(.success([]))
                        return
                    }

                    let recommendations = productRecommendations.recommendations

                    print("✅ [CartRepository] Reasoning: \(productRecommendations.reasoning)")
                    print("✅ [CartRepository] Received \(recommendations.count) recommendations")

                    // Mapear recomendaciones a Product
                    let products = recommendations.compactMap { rec -> Product? in
                        guard let product = rec.product else {
                            print(
                                "⚠️ [CartRepository] Recommendation without product: \(rec.productId)"
                            )
                            return nil
                        }

                        return Product(
                            id: product.id,
                            name: product.name,
                            shop: "Tienda",  // El producto no incluye info de branch en el schema
                            shopLogoUrl: "",
                            weight: product.currency,
                            price: "\(product.currency) \(product.price)",
                            imageUrl: product.image ?? ""
                        )
                    }

                    print(
                        "✅ [CartRepository] Mapped \(products.count) products from recommendations")
                    completion(.success(products))

                case .failure(let error):
                    print(
                        "❌ [CartRepository] Error fetching cloud recommendations: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Payment Validation

    /// Validar imagen de transferencia bancaria usando OCR (Gemini)
    /// - Parameters:
    ///   - image: Imagen del comprobante de pago
    ///   - completion: Callback con el resultado de la validación
    func validatePaymentImage(
        image: UIImage,
        transferId: String,
        completion: @escaping @Sendable (Result<PaymentValidationResult, Error>) -> Void
    ) {
        print("🔍 CartRepository: Validating payment image...")

        // Convertir UIImage a datos JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            print("❌ Error: No se pudo convertir la imagen a datos JPEG")
            completion(
                .failure(
                    NSError(
                        domain: "CartRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No se pudo procesar la imagen"]
                    )))
            return
        }

        print("✅ Imagen convertida a JPEG: \(imageData.count) bytes")

        guard !transferId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(
                .failure(
                    NSError(
                        domain: "CartRepository",
                        code: -2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "El identificador de transferencia está vacío"
                        ]
                    )))
            return
        }

        guard
            let url = URL(
                string: "https://llegobackend-production.up.railway.app/payments/validate")
        else {
            completion(
                .failure(
                    NSError(
                        domain: "CartRepository",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "URL de validación inválida"]
                    )))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let authorization = AuthManager.shared.getAuthorizationHeader() {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No hay token de autenticación, se enviará sin Authorization header")
        }

        // Construir cuerpo multipart/form-data
        var body = Data()
        let lineBreak = "\r\n"

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString(
            "Content-Disposition: form-data; name=\"transfer_id\"\(lineBreak)\(lineBreak)")
        body.appendString("\(transferId)\(lineBreak)")

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString(
            "Content-Disposition: form-data; name=\"file\"; filename=\"comprobante.jpg\"\(lineBreak)"
        )
        body.appendString("Content-Type: image/jpeg\(lineBreak)\(lineBreak)")
        body.append(imageData)
        body.appendString("\(lineBreak)")
        body.appendString("--\(boundary)--\(lineBreak)")

        request.httpBody = body
        request.timeoutInterval = 60

        print("📤 Enviando upload multipart al endpoint REST...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red validando pago: \(error.localizedDescription)")
                Task { @MainActor in completion(.failure(error)) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let error = NSError(
                    domain: "CartRepository",
                    code: -4,
                    userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"]
                )
                print("❌ Error: \(error.localizedDescription)")
                Task { @MainActor in completion(.failure(error)) }
                return
            }

            guard let data = data else {
                let error = NSError(
                    domain: "CartRepository",
                    code: -5,
                    userInfo: [NSLocalizedDescriptionKey: "El servidor no devolvió datos"]
                )
                print("❌ Error: \(error.localizedDescription)")
                Task { @MainActor in completion(.failure(error)) }
                return
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if (200...299).contains(httpResponse.statusCode) {
                do {
                    let validationResult = try decoder.decode(
                        PaymentValidationResult.self, from: data)
                    print("✅ Validación procesada. matched: \(validationResult.matched)")
                    print("   message: \(validationResult.message)")
                    print(
                        "   detectedTransferId: \(validationResult.detectedTransferId ?? "sin detectar")"
                    )

                    if let extracted = validationResult.extractedData {
                        print("   extractedData:")
                        print("     banco: \(extracted.banco ?? "desconocido")")
                        print("     quienEnvio: \(extracted.quienEnvio ?? "desconocido")")
                        print(
                            "     esMensajeBanco: \(String(describing: extracted.esMensajeBanco))")
                        print("     monto: \(String(describing: extracted.cantidadTransferida))")
                        print("     numeroTransferencia: \(extracted.numeroTransferencia ?? "n/a")")
                    }
                    if let savedPayment = validationResult.savedPayment {
                        print("   savedPaymentId: \(savedPayment.id ?? "sin id")")
                    } else {
                        print("   savedPayment: null")
                    }

                    Task { @MainActor in completion(.success(validationResult)) }
                } catch {
                    print("❌ Error decodificando respuesta: \(error.localizedDescription)")
                    Task { @MainActor in completion(.failure(error)) }
                }
            } else {
                do {
                    let errorBody = try decoder.decode(
                        PaymentValidationErrorResponse.self, from: data)
                    let apiError = NSError(
                        domain: "CartRepository",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: errorBody.message]
                    )
                    print("❌ Error API (\(httpResponse.statusCode)): \(errorBody.message)")
                    Task { @MainActor in completion(.failure(apiError)) }
                } catch {
                    let rawMessage = String(data: data, encoding: .utf8) ?? "Respuesta desconocida"
                    let apiError = NSError(
                        domain: "CartRepository",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: rawMessage]
                    )
                    print("❌ Error API (\(httpResponse.statusCode)). Raw: \(rawMessage)")
                    Task { @MainActor in completion(.failure(apiError)) }
                }
            }
        }.resume()
    }

    func fetchCloudCandidates(
        productIds: [String],
        limit: Int = 20,
        completion: @escaping @Sendable (Result<[Product], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = authManager.getAccessToken()

            print("🌐 [CartRepository] Obteniendo candidatos desde Cloud")
            print("🌐 [CartRepository] Product IDs: \(productIds)")
            print("🌐 [CartRepository] Limit: \(limit)")

            let query = LlegoAPI.GetProductRecommendationsQuery(
                productIds: productIds,
                limit: Int32(limit),
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ [CartRepository] GraphQL Errors:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        completion(
                            .failure(
                                NSError(
                                    domain: "CartRepository",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Error obteniendo candidatos"
                                    ]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        print("⚠️ [CartRepository] No data in cloud candidates response")
                        completion(.success([]))
                        return
                    }

                    guard let productRecommendations = data.productRecommendations else {
                        print(
                            "⚠️ [CartRepository] productRecommendations es nil (el backend no reconoce los productIds)"
                        )
                        completion(.success([]))
                        return
                    }

                    let recommendations = productRecommendations.recommendations
                    print("✅ [CartRepository] Received \(recommendations.count) candidatos")
                    print("   Reasoning del backend: \(productRecommendations.reasoning)")
                    recommendations.forEach { rec in
                        print(
                            "   - productId=\(rec.productId), name=\(rec.productName), hasProduct=\(rec.product != nil)"
                        )
                    }

                    let products = recommendations.compactMap { rec -> Product? in
                        guard let product = rec.product else {
                            print("   ⚠️ rec.product es nil para productId=\(rec.productId)")
                            return nil
                        }
                        return Product(
                            id: product.id,
                            name: product.name,
                            shop: "Tienda",
                            shopLogoUrl: "",
                            weight: product.currency,
                            price: "\(product.currency) \(product.price)",
                            imageUrl: product.image ?? ""
                        )
                    }

                    completion(.success(products))

                case .failure(let error):
                    print("❌ [CartRepository] Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Branch Products for Apple Intelligence

    struct BranchProductForAI {
        let id: String
        let name: String
        let description: String
        let price: Double
        let currency: String
        let imageUrl: String
    }

    /// Obtiene productos del mismo branch usando la query `productsFromSameBranch`,
    /// para enviar a Apple Intelligence y generar recomendaciones locales.
    /// - Parameter productId: ID de cualquier producto del carrito (el backend retorna productos del mismo branch)
    func fetchBranchProductsForAI(
        productId: String,
        limit: Int = 50,
        completion: @escaping @Sendable (Result<[BranchProductForAI], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = authManager.getAccessToken()

            print(
                "🤖 [CartRepository] Fetching branch products for AI via productsFromSameBranch: productId=\(productId) (limit: \(limit))"
            )

            let query = LlegoAPI.GetBranchProductsForAIQuery(
                productId: productId,
                limit: Int32(limit),
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ [CartRepository] GraphQL Errors fetching AI products:")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        completion(
                            .failure(
                                NSError(
                                    domain: "CartRepository",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Error obteniendo productos para IA"
                                    ]
                                )))
                        return
                    }

                    guard let data = graphQLResult.data else {
                        completion(.success([]))
                        return
                    }

                    let products = data.productsFromSameBranch.map { node in
                        BranchProductForAI(
                            id: node.id,
                            name: node.name,
                            description: node.description,
                            price: node.price,
                            currency: node.currency,
                            imageUrl: node.imageUrl
                        )
                    }

                    print(
                        "✅ [CartRepository] Fetched \(products.count) products for AI from same branch"
                    )
                    completion(.success(products))

                case .failure(let error):
                    print(
                        "❌ [CartRepository] Error fetching AI products: \(error.localizedDescription)"
                    )
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Models

/// Item del carrito guardado localmente (solo id + cantidad)
struct CartItemLocal: Codable, Sendable {
    var cartItemId: String
    let productId: String
    var quantity: Int
    var selectedVariants: [SelectedVariantOption]
    var comboGroupId: String?
    var comboId: String?
    var comboName: String?
    var comboComponentSlotId: String?
    var comboComponentSlotName: String?
    var comboComponentOrder: Int?
    var basePrice: Double?
    var finalUnitPrice: Double?
    var finalTotalPrice: Double

    enum CodingKeys: String, CodingKey {
        case cartItemId
        case productId
        case quantity
        case selectedVariants
        case comboGroupId
        case comboId
        case comboName
        case comboComponentSlotId
        case comboComponentSlotName
        case comboComponentOrder
        case basePrice
        case finalUnitPrice
        case finalTotalPrice
    }

    init(
        productId: String,
        quantity: Int,
        selectedVariants: [SelectedVariantOption] = [],
        comboGroupId: String? = nil,
        comboId: String? = nil,
        comboName: String? = nil,
        comboComponentSlotId: String? = nil,
        comboComponentSlotName: String? = nil,
        comboComponentOrder: Int? = nil,
        basePrice: Double? = nil,
        finalUnitPrice: Double? = nil,
        finalTotalPrice: Double? = nil,
        cartItemId: String? = nil
    ) {
        self.productId = productId
        self.quantity = quantity
        self.selectedVariants = selectedVariants
        self.comboGroupId = comboGroupId
        self.comboId = comboId
        self.comboName = comboName
        self.comboComponentSlotId = comboComponentSlotId
        self.comboComponentSlotName = comboComponentSlotName
        self.comboComponentOrder = comboComponentOrder
        self.basePrice = basePrice
        self.finalUnitPrice = finalUnitPrice
        let resolvedId =
            cartItemId
            ?? Self.buildCartItemId(productId: productId, selectedVariants: selectedVariants)
        self.cartItemId = resolvedId
        let resolvedUnit = finalUnitPrice ?? basePrice ?? 0
        self.finalTotalPrice = finalTotalPrice ?? (resolvedUnit * Double(quantity))
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try container.decode(String.self, forKey: .productId)
        quantity = try container.decode(Int.self, forKey: .quantity)
        selectedVariants =
            try container.decodeIfPresent([SelectedVariantOption].self, forKey: .selectedVariants)
            ?? []
        comboGroupId = try container.decodeIfPresent(String.self, forKey: .comboGroupId)
        comboId = try container.decodeIfPresent(String.self, forKey: .comboId)
        comboName = try container.decodeIfPresent(String.self, forKey: .comboName)
        comboComponentSlotId = try container.decodeIfPresent(
            String.self, forKey: .comboComponentSlotId)
        comboComponentSlotName = try container.decodeIfPresent(
            String.self, forKey: .comboComponentSlotName)
        comboComponentOrder = try container.decodeIfPresent(Int.self, forKey: .comboComponentOrder)
        basePrice = try container.decodeIfPresent(Double.self, forKey: .basePrice)
        finalUnitPrice = try container.decodeIfPresent(Double.self, forKey: .finalUnitPrice)
        let decodedId = try container.decodeIfPresent(String.self, forKey: .cartItemId)
        cartItemId =
            decodedId
            ?? Self.buildCartItemId(productId: productId, selectedVariants: selectedVariants)
        let decodedTotal = try container.decodeIfPresent(Double.self, forKey: .finalTotalPrice)
        let resolvedUnit = finalUnitPrice ?? basePrice ?? 0
        finalTotalPrice = decodedTotal ?? (resolvedUnit * Double(quantity))
    }

    static func buildCartItemId(productId: String, selectedVariants: [SelectedVariantOption])
        -> String
    {
        guard !selectedVariants.isEmpty else {
            return productId
        }
        let signature =
            selectedVariants
            .sorted { lhs, rhs in
                if lhs.listId == rhs.listId {
                    return lhs.optionName < rhs.optionName
                }
                return lhs.listId < rhs.listId
            }
            .map { selected in
                let optionKey = selected.optionId ?? selected.optionName
                return "\(selected.listId):\(optionKey)"
            }
            .joined(separator: "|")
        return "\(productId)::\(signature)"
    }
}

/// Estimación de costo de envío desde el backend
struct DeliveryFeeEstimate: Sendable {
    let deliveryFee: Double
    let currency: String
    let distanceKm: Double
    let zoneName: String?
    let branchId: String
    let branchName: String
}

/// Producto completo del carrito (datos GraphQL + cantidad local)
struct CartProductGraphQL: Identifiable, Sendable {
    let id: String
    let cartItemId: String
    let productId: String
    let comboGroupId: String?
    let comboId: String?
    let comboName: String?
    let comboComponentSlotId: String?
    let comboComponentSlotName: String?
    let comboComponentOrder: Int?
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let basePrice: Double
    let finalUnitPrice: Double
    let finalTotalPrice: Double
    let currency: String
    let image: String
    let availability: Bool
    let quantity: Int  // Cantidad del carrito (desde local storage)
    let businessName: String
    let selectedVariants: [SelectedVariantOption]
}

/// Resultado de validación de pago
struct PaymentValidationResult: Decodable, Sendable {
    let matched: Bool
    let message: String
    let detectedTransferId: String?
    let extractedData: ExtractedData?
    let savedPayment: SavedPayment?

    struct ExtractedData: Decodable, Sendable {
        let quienEnvio: String?
        let banco: String?
        let fecha: String?
        let esMensajeBanco: Bool?
        let cantidadTransferida: Double?
        let numeroTransferencia: String?
        let primeros4Tarjeta: String?
        let ultimos4Tarjeta: String?

        private enum CodingKeys: String, CodingKey {
            case quienEnvio
            case banco
            case fecha
            case esMensajeBanco
            case cantidadTransferida
            case numeroTransferencia
            case primeros4Tarjeta
            case ultimos4Tarjeta
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            quienEnvio = try container.decodeIfPresent(String.self, forKey: .quienEnvio)
            banco = try container.decodeIfPresent(String.self, forKey: .banco)
            fecha = try container.decodeIfPresent(String.self, forKey: .fecha)
            esMensajeBanco = try container.decodeIfPresent(Bool.self, forKey: .esMensajeBanco)
            cantidadTransferida = container.decodeFlexibleDouble(forKey: .cantidadTransferida)
            numeroTransferencia = try container.decodeIfPresent(
                String.self, forKey: .numeroTransferencia)
            primeros4Tarjeta = try container.decodeIfPresent(String.self, forKey: .primeros4Tarjeta)
            ultimos4Tarjeta = try container.decodeIfPresent(String.self, forKey: .ultimos4Tarjeta)
        }
    }

    struct SavedPayment: Decodable, Sendable {
        let id: String?
        let quienEnvio: String?
        let banco: String?
        let fecha: String?
        let esMensajeBanco: Bool?
        let cantidadTransferida: Double?
        let numeroTransferencia: String?
        let primeros4Tarjeta: String?
        let ultimos4Tarjeta: String?

        private enum CodingKeys: String, CodingKey {
            case id = "_id"
            case quienEnvio
            case banco
            case fecha
            case esMensajeBanco
            case cantidadTransferida
            case numeroTransferencia
            case primeros4Tarjeta
            case ultimos4Tarjeta
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            quienEnvio = try container.decodeIfPresent(String.self, forKey: .quienEnvio)
            banco = try container.decodeIfPresent(String.self, forKey: .banco)
            fecha = try container.decodeIfPresent(String.self, forKey: .fecha)
            esMensajeBanco = try container.decodeIfPresent(Bool.self, forKey: .esMensajeBanco)
            cantidadTransferida = container.decodeFlexibleDouble(forKey: .cantidadTransferida)
            numeroTransferencia = try container.decodeIfPresent(
                String.self, forKey: .numeroTransferencia)
            primeros4Tarjeta = try container.decodeIfPresent(String.self, forKey: .primeros4Tarjeta)
            ultimos4Tarjeta = try container.decodeIfPresent(String.self, forKey: .ultimos4Tarjeta)
        }
    }
}

private struct PaymentValidationErrorResponse: Decodable {
    let message: String
}

extension Data {
    fileprivate mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

extension KeyedDecodingContainer {
    fileprivate func decodeFlexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }

        if let stringValue = try? decode(String.self, forKey: key) {
            let normalized =
                stringValue
                .replacingOccurrences(of: ",", with: ".")
                .filter { "0123456789.".contains($0) }
            return Double(normalized)
        }

        return nil
    }
}
