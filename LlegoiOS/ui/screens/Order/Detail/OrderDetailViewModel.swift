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
    @Published var isPollingQvaPay = false
    @Published var isPollingTronDealer = false
    @Published var showTronDealerSheet = false
    @Published var tronDealerPaymentInfo: TronDealerPaymentResult?

    private let repository = OrderDetailRepository()
    private let paymentRepository = PaymentRepository()
    private let qvaPayRepository = QvaPayRepository()
    private let tronDealerRepository = TronDealerRepository()
    private let paymentMethodManager = PaymentMethodManager.shared
    private let authManager = AuthManager.shared
    private let orderId: String
    private var qvaPayPollingTask: Task<Void, Never>?
    private var tronDealerPollingTask: Task<Void, Never>?

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
        
        // QvaPay → abrir URL de pago
        if methodType == "qvapay" || method.code.lowercased().contains("qvapay") {
            initiateQvaPayPayment(order: order)
            return
        }
        
        // TronDealer → mostrar dirección y QR
        if methodType == "usdt" || method.code.lowercased().contains("trondealer") || method.code.lowercased().contains("usdt") {
            initiateTronDealerPayment(order: order)
            return
        }
        
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
        
        print("🔍 DEBUG: order.paymentMethod = '\(order.paymentMethod)'")
        print("🔍 DEBUG: methodType = '\(methodType)'")
        
        // QvaPay
        if methodType.contains("qvapay") {
            print("✅ Detectado QvaPay")
            initiateQvaPayPayment(order: order)
            return
        }
        
        // TronDealer / USDT
        if methodType.contains("usdt") || methodType.contains("trondealer") {
            print("✅ Detectado TronDealer/USDT")
            initiateTronDealerPayment(order: order)
            return
        }
        
        print("❌ No se detectó ningún método conocido")
        showPaymentAlertMessage("Método de pago no disponible. Método recibido: \(order.paymentMethod)")
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
        
        if normalized.contains("qvapay") {
            return methods.first(where: { $0.method.lowercased() == "qvapay" || $0.code.lowercased().contains("qvapay") })
        }
        
        if normalized.contains("usdt") || normalized.contains("trondealer") {
            return methods.first(where: { $0.method.lowercased() == "usdt" || $0.code.lowercased().contains("usdt") || $0.code.lowercased().contains("trondealer") })
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
    
    // MARK: - QvaPay Payment
    
    private func initiateQvaPayPayment(order: OrderDetail) {
        isInitiatingPayment = true
        
        Task {
            do {
                let result = try await qvaPayRepository.initiateQvapayPayment(orderId: order.id)
                
                await MainActor.run {
                    self.isInitiatingPayment = false
                }
                
                // Abrir URL en Safari
                if let url = URL(string: result.paymentUrl) {
                    await UIApplication.shared.open(url)
                }
                
                // Iniciar polling
                startQvaPayPolling()
                
            } catch {
                await MainActor.run {
                    self.isInitiatingPayment = false
                    let normalizedError = error.localizedDescription.lowercased()
                    if normalizedError.contains("no permite pago") || normalizedError.contains("estado no permite") || normalizedError.contains("estado del pedido") || normalizedError.contains("invalid order status") || (normalizedError.contains("order status") && normalizedError.contains("payment")) {
                        self.refresh()
                        self.showPaymentAlertMessage("El estado del pedido cambió y ya no permite pagar ahora. Actualizamos la información.")
                    } else {
                        self.showPaymentAlertMessage("No se pudo generar el enlace de pago: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func startQvaPayPolling() {
        isPollingQvaPay = true
        
        qvaPayPollingTask = Task {
            let maxAttempts = 40 // 2 minutos (40 * 3s)
            let pollingInterval: TimeInterval = 3.0
            
            for attempt in 1...maxAttempts {
                if Task.isCancelled {
                    return
                }
                
                do {
                    let updatedOrder = try await repository.fetchOrderAsync(id: orderId)
                    
                    await MainActor.run {
                        self.order = updatedOrder
                    }
                    
                    // Verificar si el pago se completó
                    if updatedOrder.paymentStatus == .completed {
                        await MainActor.run {
                            self.isPollingQvaPay = false
                            self.showPaymentAlertMessage("¡Pago completado exitosamente!")
                        }
                        return
                    }
                    
                    // Verificar si el pago falló
                    if updatedOrder.paymentStatus == .failed {
                        await MainActor.run {
                            self.isPollingQvaPay = false
                            self.showPaymentAlertMessage("El pago fue rechazado o cancelado")
                        }
                        return
                    }
                    
                } catch {
                    print("⚠️ Error en polling QvaPay attempt \(attempt): \(error)")
                }
                
                // Esperar antes del siguiente intento
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                }
            }
            
            // Timeout
            await MainActor.run {
                self.isPollingQvaPay = false
                self.showPaymentAlertMessage("No pudimos verificar tu pago automáticamente. Revisa el estado de tu orden.")
            }
        }
    }
    
    func stopQvaPayPolling() {
        qvaPayPollingTask?.cancel()
        qvaPayPollingTask = nil
        isPollingQvaPay = false
    }
    
    // MARK: - TronDealer Payment
    
    private func initiateTronDealerPayment(order: OrderDetail) {
        isInitiatingPayment = true
        
        Task {
            do {
                let result = try await tronDealerRepository.initiateTrondealerPayment(orderId: order.id)
                
                await MainActor.run {
                    self.isInitiatingPayment = false
                    self.tronDealerPaymentInfo = result
                    self.showTronDealerSheet = true
                }
                
                // Iniciar polling
                startTronDealerPolling()
                
            } catch {
                await MainActor.run {
                    self.isInitiatingPayment = false
                    let normalizedError = error.localizedDescription.lowercased()
                    if normalizedError.contains("no permite pago") || normalizedError.contains("estado no permite") || normalizedError.contains("estado del pedido") || normalizedError.contains("invalid order status") || (normalizedError.contains("order status") && normalizedError.contains("payment")) {
                        self.refresh()
                        self.showPaymentAlertMessage("El estado del pedido cambió y ya no permite pagar ahora. Actualizamos la información.")
                    } else {
                        self.showPaymentAlertMessage("No se pudo generar la dirección de pago: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func startTronDealerPolling() {
        isPollingTronDealer = true
        
        tronDealerPollingTask = Task {
            let maxAttempts = 360 // 30 minutos (360 * 5s)
            let pollingInterval: TimeInterval = 5.0
            
            for attempt in 1...maxAttempts {
                if Task.isCancelled {
                    await MainActor.run {
                        self.isPollingTronDealer = false
                    }
                    return
                }
                
                do {
                    let updatedOrder = try await repository.fetchOrderAsync(id: orderId)
                    
                    await MainActor.run {
                        self.order = updatedOrder
                    }
                    
                    // Verificar si el pago se completó
                    if updatedOrder.paymentStatus == .completed {
                        await MainActor.run {
                            self.isPollingTronDealer = false
                            self.showTronDealerSheet = false
                            self.showPaymentAlertMessage("¡Pago USDT confirmado en la blockchain!")
                        }
                        return
                    }
                    
                    // Verificar si el pago falló
                    if updatedOrder.paymentStatus == .failed {
                        await MainActor.run {
                            self.isPollingTronDealer = false
                            self.showTronDealerSheet = false
                            self.showPaymentAlertMessage("El pago fue rechazado o cancelado")
                        }
                        return
                    }
                    
                } catch {
                    print("⚠️ Error en polling TronDealer attempt \(attempt): \(error)")
                }
                
                // Esperar antes del siguiente intento
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                }
            }
            
            // Timeout
            await MainActor.run {
                self.isPollingTronDealer = false
                self.showTronDealerSheet = false
                self.showPaymentAlertMessage("No se detectó el pago. Si ya enviaste USDT, contacta con soporte.")
            }
        }
    }
    
    func stopTronDealerPolling() {
        tronDealerPollingTask?.cancel()
        tronDealerPollingTask = nil
        isPollingTronDealer = false
    }
    
    deinit {
        qvaPayPollingTask?.cancel()
        tronDealerPollingTask?.cancel()
    }
}
