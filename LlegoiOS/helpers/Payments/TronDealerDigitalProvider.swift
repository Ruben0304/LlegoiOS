import Foundation

/// Datos a mostrar en la pantalla de pago USDT (dirección + QR). Antes vivía
/// en TronDealerRepository.swift junto con la mutación dedicada; ahora es
/// solo un tipo de presentación — el proveedor lo arma decodificando
/// providerPayload en vez de llamar a una mutación aparte.
struct TronDealerPaymentResult {
    let address: String
    let expectedAmount: Double
    let network: String
    let token: String
    let orderId: String
}

/// TronDealer/USDT como proveedor de pago digital (Grupo A). Mismo patrón que
/// QvaPayDigitalProvider: el pago se inicia vía la mutación genérica
/// `initiatePayment`, y este provider solo decodifica providerPayload para
/// armar la dirección a mostrar.
@MainActor
final class TronDealerDigitalProvider: DigitalPaymentProvider {
    // El campo PaymentMethodModel.method para USDT/TronDealer es "usdt"
    // (ver también OrderPermissionPolicy) — "trondealer" es solo el nombre
    // del proveedor/servicio, no el valor real del campo `method`.
    let methodCode = "usdt"
    let pollingConfig: PaymentPollingConfig? = PaymentPollingConfig(maxAttempts: 360, interval: 5)

    func start(attempt: PaymentAttemptModel, order: OrderDetail) async throws -> PaymentPresentation {
        guard
            let payload = attempt.providerPayloadJSON,
            let data = payload.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let address = json["address"] as? String
        else {
            throw NSError(
                domain: "TronDealerDigitalProvider",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió la dirección de pago USDT."]
            )
        }

        let result = TronDealerPaymentResult(
            address: address,
            expectedAmount: attempt.totalAmount,
            network: (json["network"] as? String) ?? "TRON",
            token: (json["token"] as? String) ?? "USDT",
            orderId: order.id
        )
        return .addressDisplay(result)
    }
}
