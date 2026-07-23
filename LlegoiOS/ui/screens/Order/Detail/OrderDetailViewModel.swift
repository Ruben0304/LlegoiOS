import Combine
import Foundation
import UIKit
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
    @Published var isPollingQvaPay = false
    @Published var isPollingTronDealer = false
    @Published var showTronDealerSheet = false
    @Published var tronDealerPaymentInfo: TronDealerPaymentResult?
    @Published var showTransferSheet = false
    @Published var activePaymentAttemptId: String?
    @Published var isConfirmingTransfer = false
    @Published var transferPaymentConfirmed = false

    // Reembolso
    @Published var refundInfo: OrderRefundInfo?
    @Published var isSubmittingRefund = false
    @Published var showRefundSheet = false
    @Published var refundReason = ""

    // Calificación (rating) post-entrega
    @Published var ratingDraft: Int = 0
    @Published var ratingCommentDraft: String = ""
    @Published var isSubmittingRating = false

    private let repository = OrderDetailRepository()
    private let paymentRepository = PaymentRepository()
    private let paymentMethodManager = PaymentMethodManager.shared
    private let authManager = AuthManager.shared
    private let orderId: String
    private let paymentPoller = PaymentAttemptPoller()

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
                    print("📊 Order refreshed: status=\(detail.status.rawValue), customerVisibleStatus=\(detail.customerVisibleStatus.rawValue), paymentStatus=\(detail.paymentStatus.rawValue), deliveryVerificationCode=\(detail.deliveryVerificationCode ?? "nil")")
                    self.order = detail
                    // Reset flag local si el backend ya refleja que el pago avanzó
                    if detail.paymentStatus != .pending || detail.status != .pendingPayment {
                        self.transferPaymentConfirmed = false
                    }
                    self.loadPaymentMethodIfNeeded(for: detail)
                    self.loadRefundInfoIfNeeded(for: detail)
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


    // MARK: - Refund

    /// Carga la info de reembolso solo cuando el pago está completado (evita llamadas innecesarias).
    private func loadRefundInfoIfNeeded(for order: OrderDetail) {
        guard order.paymentStatus == .completed else {
            refundInfo = nil
            return
        }

        Task { @MainActor in
            do {
                self.refundInfo = try await repository.fetchRefundInfo(orderId: orderId)
            } catch {
                // Silencioso: si no se puede resolver el intento de pago, simplemente no
                // mostramos la sección de reembolso (no es un error accionable para el usuario).
                print("ℹ️ No se pudo cargar info de reembolso: \(error.localizedDescription)")
            }
        }
    }

    var canRequestRefund: Bool {
        refundInfo?.state == .eligible
    }

    func submitRefund() {
        guard let attemptId = refundInfo?.paymentAttemptId else { return }
        let reason = refundReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            showPaymentAlertMessage("Cuéntanos brevemente el motivo del reembolso.")
            return
        }
        guard !isSubmittingRefund else { return }

        isSubmittingRefund = true

        Task { @MainActor in
            defer { self.isSubmittingRefund = false }
            do {
                let newState = try await repository.requestRefund(
                    paymentAttemptId: attemptId, reason: reason)
                self.refundInfo?.state = newState
                self.refundReason = ""
                self.showRefundSheet = false
                self.successMessage = "Solicitud de reembolso enviada. El negocio la revisará en breve."
            } catch {
                self.showPaymentAlertMessage(
                    "No pudimos registrar tu solicitud de reembolso. \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Rate Order

    /// Se puede calificar cuando el pedido fue entregado y aún no tiene calificación.
    var canRate: Bool {
        guard let order else { return false }
        return order.status == .delivered && order.rating == nil
    }

    func submitRating() {
        guard let order else { return }
        guard (1...5).contains(ratingDraft) else { return }
        guard !isSubmittingRating else { return }

        isSubmittingRating = true

        Task { @MainActor in
            defer { self.isSubmittingRating = false }
            do {
                try await repository.rateOrder(
                    orderId: order.id, rating: ratingDraft, comment: ratingCommentDraft)
                self.ratingCommentDraft = ""
                self.ratingDraft = 0
                self.successMessage = "¡Gracias por calificar tu pedido!"
                self.load()  // Recargar para reflejar la calificación guardada
            } catch {
                self.errorMessage = error.localizedDescription
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
        
        // Si no hay paymentMethod cargado, intentar usar el de la orden directamente
        if let method = paymentMethod {
            initiatePaymentWithMethod(method, order: order)
        } else {
            // Fallback: usar order.paymentMethod directamente
            initiatePaymentWithOrderMethod(order)
        }
    }
    
    private func initiatePaymentWithMethod(_ method: PaymentMethodModel, order: OrderDetail) {
        let methodType = method.method.lowercased()

        // Grupo B: transferencia manual — flujo propio, sin cambios.
        if methodType == "transfer" || methodType == "transfermovil" {
            initiateTransferPayment(order: order, method: method)
            return
        }

        // Grupo B: wallet (saldo interno) + Grupo A: proveedores de pago
        // digital (stripe, qvapay, usdt, futuro tropipay) comparten el mismo
        // initiate genérico; el registry decide después qué presentar.
        let digitalProvider = DigitalPaymentProviderRegistry.providers[methodType]
        guard methodType == "wallet" || digitalProvider != nil else {
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
                } else if let provider = digitalProvider {
                    try await presentDigitalPayment(provider: provider, attempt: result.paymentAttempt, order: order)
                }
            } catch {
                await MainActor.run {
                    self.isInitiatingPayment = false
                }
                let normalizedError = error.localizedDescription.lowercased()
                if normalizedError.contains("no permite pago") || normalizedError.contains("estado no permite") || normalizedError.contains("estado del pedido") || normalizedError.contains("invalid order status") || (normalizedError.contains("order status") && normalizedError.contains("payment")) {
                    refresh()
                    showPaymentAlertMessage("El estado del pedido cambió y ya no permite pagar ahora. Actualizamos la información.")
                } else {
                    showPaymentAlertMessage(error.localizedDescription)
                }
            }
        }
    }

    private func initiatePaymentWithOrderMethod(_ order: OrderDetail) {
        let methodType = order.paymentMethod.lowercased()

        // Transferencia CUP — es el único método del fallback que no
        // necesita un PaymentMethodModel resuelto (paymentMethodId) para
        // arrancar.
        if methodType.contains("transfer") || methodType.contains("transfermovil") {
            initiateTransferPayment(order: order, method: nil)
            return
        }

        // Wallet y los proveedores digitales (stripe/qvapay/usdt/futuro
        // tropipay) necesitan el paymentMethodId del PaymentMethodModel
        // resuelto — no hay forma segura de iniciarlos solo con el string
        // de order.paymentMethod. Reintentar cargándolo es más seguro que
        // adivinar.
        showPaymentAlertMessage("No pudimos cargar el método de pago. Intenta de nuevo.")
    }

    /// Presenta el resultado de `provider.start(...)` y arranca el polling
    /// compartido si el proveedor lo necesita (ver PaymentPollingConfig).
    private func presentDigitalPayment(
        provider: DigitalPaymentProvider,
        attempt: PaymentAttemptModel,
        order: OrderDetail
    ) async throws {
        let presentation = try await provider.start(attempt: attempt, order: order)

        switch presentation {
        case .stripeSheet(let sheet):
            self.paymentSheet = sheet
            self.showStripePaymentSheet = true

        case .alreadyCompleted:
            self.showPaymentAlertMessage("✅ Pago procesado exitosamente.")
            refreshAfterPayment()

        case .externalRedirect(let url):
            await UIApplication.shared.open(url)

        case .addressDisplay(let info):
            self.tronDealerPaymentInfo = info
            self.showTronDealerSheet = true
        }

        if let pollingConfig = provider.pollingConfig {
            startDigitalPaymentPolling(config: pollingConfig, methodCode: provider.methodCode)
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
        // Si el cliente ya confirmó la transferencia en esta sesión, no mostrar botón de pago
        if transferPaymentConfirmed { return false }

        // Usar el método del paymentMethod cargado, o el paymentMethod de la orden como fallback
        let methodType = paymentMethod?.method ?? order.paymentMethod
        
        return OrderPermissionPolicy.canInitiateInAppPayment(
            status: order.status,
            paymentStatus: order.paymentStatus,
            paymentMethodType: methodType
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
        
        if normalized.contains("qvapay") {
            return methods.first(where: { $0.method.lowercased() == "qvapay" || $0.code.lowercased().contains("qvapay") })
        }
        
        if normalized.contains("usdt") || normalized.contains("trondealer") {
            return methods.first(where: { $0.method.lowercased() == "usdt" || $0.code.lowercased().contains("usdt") || $0.code.lowercased().contains("trondealer") })
        }

        if normalized.contains("transfer") || normalized.contains("transfermovil") {
            return methods.first(where: { $0.method.lowercased() == "transfer" || $0.method.lowercased() == "transfermovil" || $0.code.lowercased().contains("transfer") })
        }

        return nil
    }

    // MARK: - Formatting Helpers

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
    
    // MARK: - Polling de proveedores digitales (Grupo A)
    //
    // Reemplaza los dos bucles que antes vivían acá (QvaPay/TronDealer) —
    // misma mecánica, ahora en PaymentAttemptPoller, reutilizable por
    // cualquier proveedor futuro (p. ej. Tropipay) que también se confirme
    // por polling en vez de un callback de SDK.

    private func startDigitalPaymentPolling(config: PaymentPollingConfig, methodCode: String) {
        if methodCode == "qvapay" {
            isPollingQvaPay = true
        } else if methodCode == "usdt" {
            isPollingTronDealer = true
        }

        paymentPoller.start(
            config: config,
            fetchOrder: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.repository.fetchOrderAsync(id: self.orderId)
            },
            onUpdate: { [weak self] updatedOrder in
                self?.order = updatedOrder
            },
            onCompleted: { [weak self] in
                guard let self else { return }
                if methodCode == "qvapay" {
                    self.isPollingQvaPay = false
                    self.showPaymentAlertMessage("¡Pago completado exitosamente!")
                } else if methodCode == "usdt" {
                    self.isPollingTronDealer = false
                    self.showTronDealerSheet = false
                    self.showPaymentAlertMessage("¡Pago USDT confirmado en la blockchain!")
                }
            },
            onFailed: { [weak self] in
                guard let self else { return }
                if methodCode == "qvapay" {
                    self.isPollingQvaPay = false
                } else if methodCode == "usdt" {
                    self.isPollingTronDealer = false
                    self.showTronDealerSheet = false
                }
                self.showPaymentAlertMessage("El pago fue rechazado o cancelado")
            },
            onTimeout: { [weak self] in
                guard let self else { return }
                if methodCode == "qvapay" {
                    self.isPollingQvaPay = false
                    self.showPaymentAlertMessage("No pudimos verificar tu pago automáticamente. Revisa el estado de tu orden.")
                } else if methodCode == "usdt" {
                    self.isPollingTronDealer = false
                    self.showTronDealerSheet = false
                    self.showPaymentAlertMessage("No se detectó el pago. Si ya enviaste USDT, contacta con soporte.")
                }
            }
        )
    }

    func stopQvaPayPolling() {
        paymentPoller.stop()
        isPollingQvaPay = false
    }

    func stopTronDealerPolling() {
        paymentPoller.stop()
        isPollingTronDealer = false
    }

    // MARK: - Transfer CUP Payment

    private func initiateTransferPayment(order: OrderDetail, method: PaymentMethodModel?) {
        isInitiatingPayment = true

        Task {
            do {
                // Necesitamos crear un payment attempt para tener el ID de confirmación
                guard let jwt = authManager.getAccessToken() else {
                    await MainActor.run {
                        self.isInitiatingPayment = false
                        self.showPaymentAlertMessage("No hay sesión activa.")
                    }
                    return
                }

                let methodId: String
                if let method = method {
                    methodId = method.id
                } else {
                    // Sin method model cargado, mostrar sheet directamente sin payment attempt
                    await MainActor.run {
                        self.isInitiatingPayment = false
                        self.activePaymentAttemptId = nil
                        self.showTransferSheet = true
                    }
                    return
                }

                print("🔍 initiatePayment → orderId: \(order.id), paymentMethodId: \(methodId), jwtPrefix: \(String(jwt.prefix(20)))...")
                let result = try await paymentRepository.initiatePayment(
                    orderId: order.id,
                    paymentMethodId: methodId,
                    jwt: jwt,
                    includeDeliveryFee: true
                )

                await MainActor.run {
                    self.isInitiatingPayment = false
                    self.activePaymentAttemptId = result.paymentAttempt.id
                    self.showTransferSheet = true
                }
            } catch {
                await MainActor.run {
                    self.isInitiatingPayment = false
                    let msg = error.localizedDescription.lowercased()
                    if msg.contains("no permite pago") || msg.contains("estado del pedido") || msg.contains("invalid order status") {
                        self.refresh()
                        self.showPaymentAlertMessage("El estado del pedido cambió. Actualizamos la información.")
                    } else {
                        self.showPaymentAlertMessage(error.localizedDescription)
                    }
                }
            }
        }
    }

    func confirmTransferPaymentSent(proofImageData: Data?) {
        // Guard al inicio: sin attemptId no hay nada que confirmar
        guard let attemptId = activePaymentAttemptId else {
            showPaymentAlertMessage("No hay un intento de pago activo. Intenta de nuevo o contacta al negocio.")
            return
        }
        isConfirmingTransfer = true

        Task {
            do {
                if let proofData = proofImageData {
                    // Con comprobante: ConfirmPaymentSent
                    let base64 = proofData.base64EncodedString()
                    let proofUrl = "data:image/jpeg;base64,\(base64)"
                    try await repository.confirmPaymentSent(
                        paymentAttemptId: attemptId, proofUrl: proofUrl)
                } else {
                    // Sin comprobante: ConfirmTransferByShortcut
                    try await repository.confirmTransferByShortcut(paymentAttemptId: attemptId)
                }

                print("✅ confirmTransfer success, transferPaymentConfirmed = true")
                await MainActor.run {
                    self.isConfirmingTransfer = false
                    self.showTransferSheet = false
                    self.activePaymentAttemptId = nil
                    self.transferPaymentConfirmed = true
                    self.successMessage = proofImageData != nil
                        ? "¡Listo! Tu comprobante fue enviado. El negocio lo revisará en breve."
                        : "¡Listo! El negocio revisará tu pago y confirmará el pedido."
                }

                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run { self.refresh() }

            } catch {
                print("⚠️ confirmTransfer error: \(error.localizedDescription)")
                await MainActor.run {
                    self.isConfirmingTransfer = false
                    // Sheet permanece abierto para que el usuario pueda reintentar
                    self.showPaymentAlertMessage("No pudimos registrar tu pago. Verifica tu conexión e intenta de nuevo.")
                }
            }
        }
    }

}
