import Foundation

/// QvaPay como proveedor de pago digital (Grupo A). El pago se inicia con la
/// misma mutación genérica `initiatePayment` que wallet/stripe — el backend
/// devuelve la URL de checkout en `providerPayload`. Abrir esa URL y esperar
/// confirmación (polling) es responsabilidad de OrderDetailViewModel /
/// PaymentAttemptPoller, no de este provider.
@MainActor
final class QvaPayDigitalProvider: DigitalPaymentProvider {
    let methodCode = "qvapay"
    let pollingConfig: PaymentPollingConfig? = PaymentPollingConfig(maxAttempts: 40, interval: 3)

    func start(attempt: PaymentAttemptModel, order: OrderDetail) async throws -> PaymentPresentation {
        guard
            let payload = attempt.providerPayloadJSON,
            let data = payload.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let urlString = json["paymentUrl"] as? String,
            let url = URL(string: urlString)
        else {
            throw NSError(
                domain: "QvaPayDigitalProvider",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió el enlace de pago de QvaPay."]
            )
        }

        return .externalRedirect(url)
    }
}
