import Foundation
import PassKit
import Combine

class PaymentManager: NSObject, ObservableObject {
    static let shared = PaymentManager()

    @Published var paymentStatus: PaymentStatus = .idle
    @Published var lastError: String?

    enum PaymentStatus {
        case idle
        case processing
        case success
        case failed
    }

    // Merchant ID - Debes configurar esto en tu Apple Developer Account
    // Para sandbox, puedes usar un merchant ID de prueba
    private let merchantID = "merchant.com.llego.multiplatform"

    // Supported networks
    private let supportedNetworks: [PKPaymentNetwork] = [
        .visa,
        .masterCard,
        .amex,
        .discover
    ]

    // MARK: - Check if Apple Pay is available
    func canMakePayments() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }

    func canMakePaymentsUsingNetworks() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }

    // MARK: - Create Payment Request
    func createPaymentRequest(for planType: PlanType) -> PKPaymentRequest {
        let request = PKPaymentRequest()

        // Merchant info
        request.merchantIdentifier = merchantID
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US" // Cambiar según tu país
        request.currencyCode = "USD"
        request.supportedNetworks = supportedNetworks

        // Payment summary items
        let planItem = PKPaymentSummaryItem(
            label: planType == .premium ? "Plan Premium - Mensual" : "Plan Gratis",
            amount: NSDecimalNumber(string: planType == .premium ? "9.99" : "0.00")
        )

        let tax = PKPaymentSummaryItem(
            label: "Impuestos",
            amount: NSDecimalNumber(string: planType == .premium ? "1.00" : "0.00")
        )

        let total = PKPaymentSummaryItem(
            label: "Llego",
            amount: NSDecimalNumber(string: planType == .premium ? "10.99" : "0.00")
        )

        request.paymentSummaryItems = [planItem, tax, total]

        // Required billing and shipping info
        request.requiredBillingContactFields = [.emailAddress, .name]

        return request
    }

    // MARK: - Process Payment
    func processPayment(for planType: PlanType, completion: @escaping (Bool, String?) -> Void) {
        guard canMakePayments() else {
            completion(false, "Apple Pay no está disponible en este dispositivo")
            return
        }

        let request = createPaymentRequest(for: planType)

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self

        controller.present { presented in
            if !presented {
                completion(false, "No se pudo presentar Apple Pay")
            }
        }

        // Store completion handler
        self.paymentCompletionHandler = completion
    }

    // Store completion handler
    private var paymentCompletionHandler: ((Bool, String?) -> Void)?

    enum PlanType {
        case free
        case premium
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension PaymentManager: PKPaymentAuthorizationControllerDelegate {

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Aquí normalmente enviarías el payment.token a tu servidor
        // En modo sandbox, solo simulamos el proceso

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simular procesamiento exitoso
            print("✅ Payment authorized in sandbox mode")
            print("Payment token: \(payment.token)")
            print("Billing contact: \(payment.billingContact?.emailAddress ?? "N/A")")

            // En producción, aquí verificarías con tu backend
            let success = true

            if success {
                self.paymentStatus = .success
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                self.paymentCompletionHandler?(true, nil)
            } else {
                self.paymentStatus = .failed
                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                self.paymentCompletionHandler?(false, "Error al procesar el pago")
            }
        }
    }

    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            print("Apple Pay controller dismissed")
        }
    }
}

// MARK: - Sandbox Testing Helpers
extension PaymentManager {
    /// Para testing en sandbox - verifica el estado de Apple Pay
    func getApplePayStatus() -> String {
        if canMakePayments() {
            if canMakePaymentsUsingNetworks() {
                return "✅ Apple Pay disponible con tarjetas configuradas"
            } else {
                return "⚠️ Apple Pay disponible pero sin tarjetas"
            }
        } else {
            return "❌ Apple Pay no disponible en este dispositivo"
        }
    }

    /// Simular diferentes escenarios de pago para testing
    func simulatePaymentScenario(_ scenario: PaymentScenario) {
        switch scenario {
        case .success:
            paymentStatus = .success
            lastError = nil
        case .failure:
            paymentStatus = .failed
            lastError = "Tarjeta rechazada (simulación)"
        case .userCancelled:
            paymentStatus = .idle
            lastError = "Usuario canceló el pago"
        }
    }

    enum PaymentScenario {
        case success
        case failure
        case userCancelled
    }
}
