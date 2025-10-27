import Foundation

/// Respuesta del backend al crear un PaymentIntent
/// Esta estructura debe coincidir con lo que devuelve el endpoint del backend
struct PaymentIntentResponse: Codable, Sendable {
    /// Client secret del PaymentIntent (para completar el pago)
    let paymentIntent: String

    /// Secret de la Ephemeral Key (para acceder al Customer)
    let ephemeralKey: String

    /// ID del Customer de Stripe
    let customer: String

    /// Publishable Key de Stripe
    let publishableKey: String

    enum CodingKeys: String, CodingKey {
        case paymentIntent
        case ephemeralKey
        case customer
        case publishableKey
    }
}

/// Request para crear un PaymentIntent
struct CreatePaymentIntentRequest: Codable {
    /// Monto en centavos (ej: 4550 para $45.50)
    let amount: Int

    /// Código de divisa (ej: "usd", "eur")
    let currency: String

    /// ID del customer (opcional, si ya existe)
    let customerId: String?

    /// Email del customer (opcional, para crear nuevo customer)
    let customerEmail: String?

    /// Metadatos adicionales
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case customerId = "customer_id"
        case customerEmail = "customer_email"
        case metadata
    }
}
