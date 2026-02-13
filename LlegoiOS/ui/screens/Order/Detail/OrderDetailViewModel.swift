import Combine
import Foundation
import PassKit
import StripePaymentSheet

@MainActor
final class OrderDetailViewModel: ObservableObject {
    @Published var order: OrderDetail?
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var isInitiatingPayment = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var paymentAlertMessage: String?
    @Published var showPaymentAlert = false
    @Published var newComment: String = ""
    @Published var paymentMethod: PaymentMethodModel?
    @Published var isLoadingPaymentMethod = false
    @Published var paymentSheet: PaymentSheet?
    @Published var showStripePaymentSheet = false

    private let repository = OrderDetailRepository()
    private let paymentRepository = PaymentRepository()
    private let paymentMethodManager = PaymentMethodManager.shared
    private let authManager = AuthManager.shared
    private let orderId: String

    init(orderId: String) {
        self.orderId = orderId
        load()
    }

    // MARK: - Load Order

    func load() {
        isLoading = true
        errorMessage = nil

        repository.fetchOrder(id: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let detail):
                    self.order = detail
                    self.loadPaymentMethodIfNeeded(for: detail)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Refresh

    func refresh() {
        load()
    }

    // MARK: - Accept Modifications

    func acceptModifications(onSuccess: @escaping @Sendable () -> Void = {}) {
        guard
            let order = order,
            OrderPermissionPolicy.canAcceptModifications(status: order.status)
        else { return }

        isProcessing = true
        errorMessage = nil

        repository.acceptModifications(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false

                switch result {
                case .success(let updatedOrder):
                    self.order = updatedOrder
                    self.successMessage = "Modificaciones aceptadas"
                    onSuccess()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Cancel Order

    func cancelOrder(reason: String? = nil, onSuccess: @escaping @Sendable () -> Void = {}) {
        guard let order = order, order.canCancel else { return }

        isProcessing = true
        errorMessage = nil

        repository.cancelOrder(orderId: orderId, reason: reason) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false

                switch result {
                case .success(let updatedOrder):
                    self.order = updatedOrder
                    self.successMessage = "Pedido cancelado"
                    onSuccess()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Add Comment

    func sendComment() {
        let message = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        isProcessing = true

        repository.addComment(orderId: orderId, message: message) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isProcessing = false

                switch result {
                case .success:
                    self.newComment = ""
                    self.load()  // Reload to get updated comments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Payment Flow

    func initiatePayment() {
        guard let order = order else { return }
        guard let method = paymentMethod else {
            showPaymentAlertMessage("Método de pago no disponible.")
            return
        }

        let methodType = method.method.lowercased()
        guard ["wallet", "stripe"].contains(methodType) else {
            showPaymentAlertMessage("Este método de pago aún no está disponible.")
            return
        }

        guard let jwt = authManager.getAccessToken() else {
            showPaymentAlertMessage("No hay sesión activa.")
            return
        }

        isInitiatingPayment = true

        Task {
            do {
                let result = try await paymentRepository.initiatePayment(
                    orderId: order.id,
                    paymentMethodId: method.id,
                    jwt: jwt,
                    includeDeliveryFee: true
                )

                await MainActor.run {
                    self.isInitiatingPayment = false
                }

                if methodType == "wallet" {
                    handleWalletPaymentResult(result.paymentAttempt)
                } else {
                    try await presentStripePaymentSheet(using: result.paymentAttempt)
                }
            } catch {
                await MainActor.run {
                    self.isInitiatingPayment = false
                }
                showPaymentAlertMessage(error.localizedDescription)
            }
        }
    }

    func handleStripePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            showPaymentAlertMessage("Pago completado. Estamos confirmando la transacción.")
            refreshAfterPayment()
        case .canceled:
            showPaymentAlertMessage("Pago cancelado.")
        case .failed(let error):
            showPaymentAlertMessage("Error en el pago: \(error.localizedDescription)")
        }

        paymentSheet = nil
    }

    func canInitiatePayment(for order: OrderDetail) -> Bool {
        OrderPermissionPolicy.canInitiateInAppPayment(
            status: order.status,
            paymentStatus: order.paymentStatus,
            paymentMethodType: paymentMethod?.method
        )
    }

    private func handleWalletPaymentResult(_ attempt: PaymentAttemptModel) {
        switch attempt.status.lowercased() {
        case "completed":
            showPaymentAlertMessage("Pago confirmado con Wallet.")
            refreshAfterPayment()
        case "failed":
            showPaymentAlertMessage("Pago rechazado. Intenta nuevamente.")
        default:
            showPaymentAlertMessage("Pago en proceso. Te avisaremos cuando se confirme.")
            refreshAfterPayment()
        }
    }

    private func presentStripePaymentSheet(using attempt: PaymentAttemptModel) async throws {
        guard let clientSecret = attempt.stripeClientSecret else {
            throw NSError(
                domain: "OrderDetailViewModel",
                code: -6,
                userInfo: [NSLocalizedDescriptionKey: "No se recibió el client secret de Stripe."]
            )
        }

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Llego"
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = StripeConfig.returnURL

        if StripeConfig.enableApplePay, PKPaymentAuthorizationController.canMakePayments() {
            configuration.applePay = .init(
                merchantId: StripeConfig.applePayMerchantId,
                merchantCountryCode: StripeConfig.merchantCountryCode
            )
        }

        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: configuration
        )
        self.showStripePaymentSheet = true
    }

    private func refreshAfterPayment() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            self.refresh()
        }
    }

    private func showPaymentAlertMessage(_ message: String) {
        Task { @MainActor in
            self.paymentAlertMessage = message
            self.showPaymentAlert = true
        }
    }

    private func loadPaymentMethodIfNeeded(for order: OrderDetail) {
        guard paymentMethod?.code.lowercased() != order.paymentMethod.lowercased() else { return }

        isLoadingPaymentMethod = true

        Task {
            do {
                let methods = try await paymentMethodManager.fetchPaymentMethods()
                let resolved = resolvePaymentMethod(from: methods, code: order.paymentMethod)

                await MainActor.run {
                    self.paymentMethod = resolved
                    self.isLoadingPaymentMethod = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPaymentMethod = false
                    self.paymentMethod = nil
                }
            }
        }
    }

    private func resolvePaymentMethod(from methods: [PaymentMethodModel], code: String)
        -> PaymentMethodModel?
    {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let exact = methods.first(where: { $0.code.lowercased() == normalized }) {
            return exact
        }

        if let byMethod = methods.first(where: { $0.method.lowercased() == normalized }) {
            return byMethod
        }

        if normalized.contains("wallet") {
            return methods.first(where: { $0.method.lowercased() == "wallet" })
        }

        if normalized.contains("stripe") {
            return methods.first(where: { $0.method.lowercased() == "stripe" })
        }

        return nil
    }

    // MARK: - Formatting Helpers

    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, HH:mm"
        formatter.locale = Locale(identifier: "es")
        return formatter.string(from: date)
    }

    // MARK: - Computed Properties

    var canAcceptModifications: Bool {
        guard let status = order?.status else { return false }
        return OrderPermissionPolicy.canAcceptModifications(status: status)
    }

    var canCancelOrder: Bool {
        order?.canCancel ?? false
    }

    var showDeliveryPerson: Bool {
        guard let status = order?.status else { return false }
        return OrderPermissionPolicy.canShowTracking(status: status)
    }

    var showTimeline: Bool {
        !(order?.timeline.isEmpty ?? true)
    }
}
