import Foundation

/// Repository para manejar pagos con Stripe
class PaymentRepository {

    /// Crea un PaymentIntent usando la API de Stripe directamente (SOLO PARA TESTING)
    /// ⚠️ IMPORTANTE: Este método NO debe usarse en producción.
    /// En producción, SIEMPRE debes crear PaymentIntents desde tu backend.
    /// Este método existe solo para testing sin backend.
    func createPaymentIntentDirectly(
        amount: Int,
        currency: String,
        completion: @escaping @Sendable (Result<PaymentIntentResponse, Error>) -> Void
    ) {
        // Crear URL de la API de Stripe
        guard let url = URL(string: "https://api.stripe.com/v1/payment_intents") else {
            completion(.failure(PaymentError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Usar la Secret Key en el header (SOLO PARA TESTING)
        // ⚠️ NUNCA hacer esto en producción
        let secretKey = "sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk"
        let authString = "\(secretKey):"
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Crear body con parámetros
        var bodyParams = [
            "amount": "\(amount)",
            "currency": currency.lowercased()
        ]

        // Habilitar métodos de pago automáticos (incluye tarjetas, Apple Pay, pagos a plazos, etc.)
        if StripeConfig.enableInstallments {
            bodyParams["automatic_payment_methods[enabled]"] = "true"
            print("   ✅ Pagos a plazos habilitados (Affirm, Afterpay, Klarna)")
        } else {
            bodyParams["payment_method_types[]"] = "card"
        }

        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        print("🧪 [MOCK MODE] Creando PaymentIntent directamente con Stripe API")
        print("   Amount: \(amount) \(currency)")

        // Ejecutar request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(PaymentError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(PaymentError.noData))
                return
            }

            // Para debugging, imprimir la respuesta
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Response: \(jsonString.prefix(200))...")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                completion(.failure(PaymentError.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            do {
                // Parsear respuesta de Stripe
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let clientSecret = json["client_secret"] as? String,
                   let paymentIntentId = json["id"] as? String {

                    print("✅ [MOCK MODE] PaymentIntent creado: \(paymentIntentId)")

                    // Crear respuesta mock (sin Customer ni EphemeralKey porque no los necesitamos para testing básico)
                    let mockResponse = PaymentIntentResponse(
                        paymentIntent: clientSecret,
                        ephemeralKey: "ek_test_mock", // Mock - no se usará
                        customer: "cus_mock", // Mock - no se usará
                        publishableKey: StripeConfig.publishableKey
                    )

                    completion(.success(mockResponse))
                } else {
                    completion(.failure(PaymentError.invalidResponse))
                }
            } catch {
                print("❌ Error parsing JSON: \(error)")
                completion(.failure(error))
            }
        }

        task.resume()
    }

    /// Crea un PaymentIntent en el backend
    /// - Parameters:
    ///   - amount: Monto en centavos (ej: 4550 para $45.50)
    ///   - currency: Código de divisa en minúsculas (ej: "usd", "eur")
    ///   - customerId: ID del customer existente (opcional)
    ///   - customerEmail: Email para crear nuevo customer (opcional)
    ///   - metadata: Metadatos adicionales (opcional)
    ///   - completion: Callback con el resultado
    func createPaymentIntent(
        amount: Int,
        currency: String,
        customerId: String? = nil,
        customerEmail: String? = nil,
        metadata: [String: String]? = nil,
        completion: @escaping @Sendable (Result<PaymentIntentResponse, Error>) -> Void
    ) {
        // Crear URL del endpoint
        guard let url = URL(string: StripeConfig.paymentIntentURL) else {
            completion(.failure(PaymentError.invalidURL))
            return
        }

        // Crear request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Crear body del request
        let requestBody = CreatePaymentIntentRequest(
            amount: amount,
            currency: currency.lowercased(),
            customerId: customerId,
            customerEmail: customerEmail,
            metadata: metadata
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("❌ Error encoding request: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Ejecutar request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Manejar error de red
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            // Verificar respuesta HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(PaymentError.invalidResponse))
                return
            }

            // Verificar status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    print("❌ Error message: \(errorMessage)")
                }
                completion(.failure(PaymentError.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            // Decodificar respuesta
            guard let data = data else {
                completion(.failure(PaymentError.noData))
                return
            }

            do {
                let response = try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
                print("✅ PaymentIntent created successfully")
                print("   Customer: \(response.customer)")
                print("   PaymentIntent: \(response.paymentIntent.prefix(20))...")
                completion(.success(response))
            } catch {
                print("❌ Error decoding response: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("❌ Response JSON: \(jsonString)")
                }
                completion(.failure(error))
            }
        }

        task.resume()
    }

    /// Crea un Payment Link de Stripe que se puede compartir
    /// - Parameters:
    ///   - amount: Monto en centavos (ej: 4550 para $45.50)
    ///   - currency: Código de divisa en minúsculas (ej: "usd", "eur")
    ///   - metadata: Metadatos adicionales (opcional)
    ///   - completion: Callback con la URL del payment link
    func createPaymentLink(
        amount: Int,
        currency: String,
        metadata: [String: String]? = nil,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        // Crear URL de la API de Stripe
        guard let url = URL(string: "https://api.stripe.com/v1/payment_links") else {
            completion(.failure(PaymentError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Usar la Secret Key en el header
        let secretKey = "sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk"
        let authString = "\(secretKey):"
        let authData = authString.data(using: .utf8)!
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Crear body con parámetros
        var bodyParams = [
            "line_items[0][price_data][currency]": currency.lowercased(),
            "line_items[0][price_data][product_data][name]": "Pedido Llego",
            "line_items[0][price_data][unit_amount]": "\(amount)",
            "line_items[0][quantity]": "1",
            "after_completion[type]": "hosted_confirmation",
            "after_completion[hosted_confirmation][custom_message]": "¡Gracias por tu pago! Tu pedido será procesado pronto."
        ]

        // Añadir metadatos si existen
        if let metadata = metadata {
            for (index, item) in metadata.enumerated() {
                bodyParams["metadata[\(item.key)]"] = item.value
            }
        }

        let bodyString = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        print("🔗 Creando Payment Link de Stripe")
        print("   Amount: \(amount) \(currency)")

        // Ejecutar request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error de red: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(PaymentError.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.failure(PaymentError.noData))
                return
            }

            // Para debugging, imprimir la respuesta
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📥 Response: \(jsonString.prefix(300))...")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                completion(.failure(PaymentError.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            do {
                // Parsear respuesta de Stripe
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let paymentLinkURL = json["url"] as? String {

                    print("✅ Payment Link creado: \(paymentLinkURL)")
                    completion(.success(paymentLinkURL))
                } else {
                    completion(.failure(PaymentError.invalidResponse))
                }
            } catch {
                print("❌ Error parsing JSON: \(error)")
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

// MARK: - Payment Errors
enum PaymentError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL del endpoint de pago es inválida"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .noData:
            return "No se recibieron datos del servidor"
        case .httpError(let statusCode):
            return "Error HTTP: \(statusCode)"
        }
    }
}
