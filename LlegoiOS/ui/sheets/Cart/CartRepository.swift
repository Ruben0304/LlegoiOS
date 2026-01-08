import Foundation
import Apollo
import UIKit
import Combine

@MainActor
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
            query: LlegoAPI.GetCartProductsQuery(
                first: Int32(100),
                after: .none,
                ids: productIds
            ),
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

                guard let data = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                // Mapear GraphQL products y combinar con cantidades locales
                let mappedProducts = data.edges.compactMap { edge -> CartProductGraphQL? in
                    guard let localItem = localItems.first(where: { $0.productId == edge.node.id }) else {
                        return nil
                    }

                    return CartProductGraphQL(
                        id: edge.node.id,
                        branchId: edge.node.branchId,
                        name: edge.node.name,
                        description: edge.node.description,
                        weight: edge.node.weight,
                        price: edge.node.price,
                        currency: edge.node.currency,
                        image: edge.node.image,
                        availability: edge.node.availability,
                        quantity: localItem.quantity,
                        businessName: edge.node.business?.name ?? "Tienda"
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
            completion(.failure(NSError(
                domain: "CartRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se pudo procesar la imagen"]
            )))
            return
        }

        print("✅ Imagen convertida a JPEG: \(imageData.count) bytes")

        guard !transferId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(
                domain: "CartRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "El identificador de transferencia está vacío"]
            )))
            return
        }

        guard let url = URL(string: "https://llegobackend-production.up.railway.app/payments/validate") else {
            completion(.failure(NSError(
                domain: "CartRepository",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "URL de validación inválida"]
            )))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let authorization = AuthManager.shared.getAuthorizationHeader() {
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No hay token de autenticación, se enviará sin Authorization header")
        }

        // Construir cuerpo multipart/form-data
        var body = Data()
        let lineBreak = "\r\n"

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString("Content-Disposition: form-data; name=\"transfer_id\"\(lineBreak)\(lineBreak)")
        body.appendString("\(transferId)\(lineBreak)")

        body.appendString("--\(boundary)\(lineBreak)")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"comprobante.jpg\"\(lineBreak)")
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
                    let validationResult = try decoder.decode(PaymentValidationResult.self, from: data)
                    print("✅ Validación procesada. matched: \(validationResult.matched)")
                    print("   message: \(validationResult.message)")
                    print("   detectedTransferId: \(validationResult.detectedTransferId ?? "sin detectar")")

                    if let extracted = validationResult.extractedData {
                        print("   extractedData:")
                        print("     banco: \(extracted.banco ?? "desconocido")")
                        print("     quienEnvio: \(extracted.quienEnvio ?? "desconocido")")
                        print("     esMensajeBanco: \(String(describing: extracted.esMensajeBanco))")
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
                    let errorBody = try decoder.decode(PaymentValidationErrorResponse.self, from: data)
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
    let businessName: String
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
            numeroTransferencia = try container.decodeIfPresent(String.self, forKey: .numeroTransferencia)
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
            numeroTransferencia = try container.decodeIfPresent(String.self, forKey: .numeroTransferencia)
            primeros4Tarjeta = try container.decodeIfPresent(String.self, forKey: .primeros4Tarjeta)
            ultimos4Tarjeta = try container.decodeIfPresent(String.self, forKey: .ultimos4Tarjeta)
        }
    }
}

private struct PaymentValidationErrorResponse: Decodable {
    let message: String
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }

        if let stringValue = try? decode(String.self, forKey: key) {
            let normalized = stringValue
                .replacingOccurrences(of: ",", with: ".")
                .filter { "0123456789.".contains($0) }
            return Double(normalized)
        }

        return nil
    }
}
