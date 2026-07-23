import Foundation
import StripePaymentSheet

/// Contrato común del Grupo A: proveedores de pago digital externos
/// (stripe, qvapay, usdt/TronDealer, futuro tropipay).
///
/// Todos comparten el mismo ciclo de vida: el `PaymentAttempt` ya se creó vía
/// la mutación genérica `initiatePayment` (igual que hoy para wallet/stripe);
/// lo que cada proveedor decide es CÓMO presentárselo al usuario. El polling
/// posterior (si aplica) lo maneja `PaymentAttemptPoller`, no cada provider.
///
/// Grupo B (wallet, transfer, cash) NO implementa este protocolo — son
/// liquidaciones manuales/internas con su propia forma, no "otro proveedor
/// más".
@MainActor
protocol DigitalPaymentProvider {
    /// Debe matchear `PaymentMethodModel.method` tal como lo manda el backend
    /// (p. ej. "stripe", "qvapay", "usdt").
    var methodCode: String { get }

    /// `nil` cuando la confirmación llega por otro medio que no es polling
    /// (p. ej. Stripe se resuelve por el callback del propio SDK).
    var pollingConfig: PaymentPollingConfig? { get }

    func start(attempt: PaymentAttemptModel, order: OrderDetail) async throws -> PaymentPresentation
}

enum PaymentPresentation {
    case stripeSheet(PaymentSheet)
    case externalRedirect(URL)
    case addressDisplay(TronDealerPaymentResult)
    /// El backend ya completó el pago (p. ej. tienda demo) — nada que presentar.
    case alreadyCompleted
}

struct PaymentPollingConfig {
    let maxAttempts: Int
    let interval: TimeInterval
}
