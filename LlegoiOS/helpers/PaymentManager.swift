import Foundation
import Combine

final class PaymentManager: NSObject, ObservableObject {
    @MainActor static let shared = PaymentManager()

    @Published var paymentStatus: PaymentStatus = .idle
    @Published var lastError: String?

    enum PaymentStatus {
        case idle
        case processing
        case success
        case failed
    }

    enum PaymentScenario {
        case success
        case failure
        case userCancelled
    }

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
}
