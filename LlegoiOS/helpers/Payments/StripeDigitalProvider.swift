import Foundation
import StripePaymentSheet

/// Stripe como proveedor de pago digital (Grupo A). Misma lógica que antes
/// vivía en OrderDetailViewModel.presentStripePaymentSheet, solo reubicada.
@MainActor
final class StripeDigitalProvider: DigitalPaymentProvider {
    let methodCode = "stripe"

    /// Stripe se resuelve por el callback del propio SDK
    /// (OrderDetailViewModel.handleStripePaymentResult), no por polling.
    let pollingConfig: PaymentPollingConfig? = nil

    func start(attempt: PaymentAttemptModel, order: OrderDetail) async throws -> PaymentPresentation {
        // Demo mode: el backend ya completó el pago — no hace falta sheet.
        if attempt.status.lowercased() == "completed" && attempt.stripeClientSecret == nil {
            return .alreadyCompleted
        }

        guard let clientSecret = attempt.stripeClientSecret else {
            throw NSError(
                domain: "StripeDigitalProvider",
                code: -6,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió el client secret de Stripe."]
            )
        }

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Llego"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = StripeConfig.returnURL

        let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
        return .stripeSheet(sheet)
    }
}
