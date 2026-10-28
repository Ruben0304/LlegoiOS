import AVFoundation
import AudioToolbox
import Combine
import CoreLocation
import CryptoKit
import LocalAuthentication
import StripePaymentSheet
import SwiftUI
import UIKit

enum Currency: String, CaseIterable {
    case CUP = "CUP"
    case USD = "USD"

    var flag: String {
        switch self {
        case .CUP: return "🇨🇺"
        case .USD: return "🇺🇸"
        }
    }

    var title: String {
        switch self {
        case .CUP: return "Peso Cubano"
        case .USD: return "Dólar"
        }
    }
}

struct CartView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CartViewModel()
    @ObservedObject private var locationManager = UserLocationManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selectedCurrency: Currency = .CUP
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showPaymentMethodPicker = false
    @State private var showOrdersFromCart = false
    @State private var showCartAnimationPreview = false

    // MARK: - Stripe PaymentSheet
    @State private var paymentSheet: PaymentSheet?
    @State private var isLoadingPayment = false
    @State private var paymentResult: PaymentSheetResult?
    @State private var showPaymentAlert = false
    @State private var paymentAlertMessage = ""
    @State private var generatedPaymentLink: String?
    @State private var showPaymentLinkSheet = false
    @State private var showBankTransferSheet = false
    @State private var showOrderConfirmation = false
    @State private var showTransferSmsSheet = false
    @State private var showScheduledOrderPicker = false
    @State private var pendingTransferPaymentMethodId: String?
    @State private var preInitiatedPaymentResult: InitiatePaymentResultModel?
    @State private var cashKycFlowContext: CashKycFlowContext?
    @State private var showAccountCashKycSheet = false
    @State private var cashKycStatusSnapshot: CashKycDecisionSnapshot?
    @State private var isLoadingCashKycStatus = false
    private let paymentRepository = PaymentRepository()

    // MARK: - Ad Discount States
    @State private var showAdView = false
    @State private var showAddressPicker = false
    @State private var showDeliveryAddressAlert = false

    // MARK: - Fly-to-cart Animation
    @State private var flyingParticles: [FlyingParticle] = []
    @State private var cartItemsCardFrame: CGRect = .zero

    // MARK: - Computed Properties

    /// Métodos de pago disponibles (desde el backend)
    var availablePaymentMethods: [PaymentMethod] {
        viewModel.paymentMethods.map { PaymentMethod.from($0) }
    }

    /// Métodos de pago filtrados por moneda seleccionada
    var filteredPaymentMethods: [PaymentMethod] {
        let currencyCode = selectedCurrency.rawValue
        return availablePaymentMethods.filter { method in
            paymentMethodSupportsCurrency(method.currency, currencyCode: currencyCode)
        }
    }

    /// Siempre ofrecer ambas monedas; los items que no soporten la seleccionada
    /// mostrarán un cartel informativo y mantendrán su precio original.
    var availableCurrencies: [Currency] {
        Currency.allCases
    }

    var cartDisplayEntries: [CartDisplayEntry] {
        var entries: [CartDisplayEntry] = []
        var seenComboGroups = Set<String>()

        for item in viewModel.cartItems {
            if let comboGroupId = item.comboGroupId {
                guard seenComboGroups.insert(comboGroupId).inserted else { continue }
                let components = viewModel.cartItems.filter { $0.comboGroupId == comboGroupId }
                guard
                    let primaryItem = components.min(by: {
                        ($0.comboComponentOrder ?? .max) < ($1.comboComponentOrder ?? .max)
                    })
                else { continue }
                entries.append(
                    CartDisplayEntry(
                        id: comboGroupId,
                        kind: .combo(primaryItem: primaryItem, components: components)
                    )
                )
            } else {
                entries.append(
                    CartDisplayEntry(
                        id: item.id,
                        kind: .single(item)
                    )
                )
            }
        }

        return entries
    }

    var body: some View {
        NavigationStack {
            cartSheetsLayer
                .alert("Estado del Pago", isPresented: $showPaymentAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(paymentAlertMessage)
                }
                .overlay {
                    if isLoadingPayment { cartLoadingOverlay }
                }
                .onAppear {
                    viewModel.loadCart()
                    ensureSelectedCurrencyIsValid()
                    viewModel.selectedCurrency = selectedCurrency.rawValue
                }
                .onChange(of: selectedCurrency) { _, newValue in
                    viewModel.selectedCurrency = newValue.rawValue
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                        normalizeDeliveryFeePaymentMode()
                    }
                }
                .onChange(of: viewModel.cartItems) { _, _ in ensureSelectedCurrencyIsValid() }
                .onChange(of: selectedPaymentMethod?.id) { _, _ in refreshCashKycStatusBanner() }
                .onChange(of: viewModel.paymentMethods.count) { _, _ in refreshCashKycStatusBanner() }
                .fullScreenCover(isPresented: $showOrderConfirmation) {
                    OrderConfirmationView(
                        deliveryLocation: orderConfirmationLocationLabel,
                        selectedPaymentMethod: selectedPaymentMethod?.name ?? "Método de Pago",
                        onDismiss: {
                            showOrderConfirmation = false
                            dismiss()
                            NotificationCenter.default.post(name: .openOrdersFromCheckout, object: nil)
                        }
                    )
                    .onAppear {
                        // Momento con contexto para pedir permiso: avisar cambios de este pedido
                        PushNotificationManager.shared.requestPermissionAndRegister()
                    }
                }
                .fullScreenCover(isPresented: $showOrdersFromCart, content: ordersFromCartCover)
        }
        .fullScreenCover(isPresented: $showCartAnimationPreview) {
            FirstCartCelebration(
                photo: CartFlightPhoto(imageURL: viewModel.cartItems.first?.imageUrl, cacheKey: nil),
                accent: cartAccent,
                onFinish: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) { showCartAnimationPreview = false }
                })
                .presentationBackground(.clear)
        }
    }

    // MARK: - Cart Sheets Layer

    private var cartSheetsLayer: some View {
        ZStack(alignment: .top) {
            cartGradientBackground
                .ignoresSafeArea()
            cartContent
            flyingParticlesOverlay
        }
        .navigationTitle("Carrito")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { cartToolbarItems }
        .tint(cartAccent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsCheckoutDock { checkoutDock }
        }
        .sheet(isPresented: $showPaymentMethodPicker) {
            PaymentMethodPickerView(
                paymentMethods: filteredPaymentMethods,
                selectedMethod: $selectedPaymentMethod
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaymentLinkSheet) {
            PaymentLinkSheetView(
                paymentLink: generatedPaymentLink ?? "",
                onDismiss: { showPaymentLinkSheet = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBankTransferSheet) { bankTransferSheetContent }
        .sheet(isPresented: $showTransferSmsSheet) { transferSmsSheetContent }
        .sheet(isPresented: $showAddressPicker) {
            SavedAddressesView(isSelectingDeliveryAddress: true) { address in
                viewModel.selectedAddress = address
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Dirección de entrega", isPresented: $showDeliveryAddressAlert, titleVisibility: .visible) {
            Button("Esta dirección") { processPayment() }
            Button("Otra dirección") { showAddressPicker = true }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(deliveryAddressAlertMessage)
        }
        .sheet(isPresented: $showScheduledOrderPicker) {
            if let schedule = viewModel.branchSchedule {
                ScheduledOrderPickerView(
                    schedule: schedule,
                    selectedDate: $viewModel.scheduledFor
                )
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(item: $cashKycFlowContext) { context in
            CashKycFlowSheet(context: context) {
                handleCashKycApproved(context)
            } onBlocked: { message, suggestChangeMethod in
                handleCashKycBlocked(message: message, suggestChangeMethod: suggestChangeMethod)
            }
        }
        .sheet(isPresented: $showAccountCashKycSheet) {
            CartAccountCashKycSheet { completionMessage in
                paymentAlertMessage = completionMessage
                showPaymentAlert = true
                refreshCashKycStatusBanner()
            }
        }
    }

    // MARK: - Loading Overlay

    private var cartLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView().controlSize(.large).tint(cartAccent)
                Text("Preparando tu pedido…")
                    .font(.system(.headline, design: .rounded))
                Text("Un momento, por favor")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .modifier(CartSurface())
            .padding(24)
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var cartToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(cartAccent)
            }
            .accessibilityLabel("Cerrar carrito")
        }

        #if DEBUG
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCartAnimationPreview = true
            } label: {
                Image(systemName: "play.circle")
            }
            .accessibilityLabel("Probar animación del carrito")
            .disabled(viewModel.isCreatingOrder || isLoadingPayment)
        }
        #endif

        ToolbarItem(placement: .navigationBarTrailing) {
            if availableCurrencies.count > 1 {
                Menu {
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Button(action: {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedCurrency = currency
                            }
                        }) {
                            if selectedCurrency == currency {
                                Label(currency.rawValue, systemImage: "checkmark")
                            } else {
                                Text(currency.rawValue)
                            }
                        }
                    }
                } label: {
                    Label(selectedCurrency.rawValue, systemImage: "chevron.down")
                        .font(.system(.subheadline, weight: .semibold))
                }
                .accessibilityLabel("Moneda: \(selectedCurrency.rawValue)")
                .accessibilityHint("Cambiar la moneda del pedido")
                .disabled(viewModel.isRefreshingCart || viewModel.isCreatingOrder || isLoadingPayment)
            } else {
                Text(selectedCurrency.rawValue)
            }
        }

    }

    // MARK: - Sheet Contents

    @ViewBuilder
    private var bankTransferSheetContent: some View {
        BankTransferSheetView(
            totalAmount: viewModel.formattedTotal,
            onConfirm: { _ in
                showBankTransferSheet = false
                if let preResult = preInitiatedPaymentResult {
                    viewModel.confirmPaymentSent(
                        paymentAttemptId: preResult.paymentAttempt.id,
                        proofUrl: ""
                    ) { result in
                        Task { @MainActor in
                            preInitiatedPaymentResult = nil
                            switch result {
                            case .success:
                                if let createdOrder = viewModel.createdOrder {
                                    startOrderTracking(for: createdOrder)
                                }
                                viewModel.clearCart()
                                showOrderConfirmation = true
                            case .failure(let error):
                                paymentAlertMessage = error.localizedDescription
                                showPaymentAlert = true
                            }
                        }
                    }
                } else {
                    preInitiatedPaymentResult = nil
                    createOrderWithPaymentMethod("bank_transfer")
                }
            },
            onDismiss: {
                showBankTransferSheet = false
                preInitiatedPaymentResult = nil
            }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var transferSmsSheetContent: some View {
        if let methodId = pendingTransferPaymentMethodId {
            TransferSmsConfirmationView(
                cartViewModel: viewModel,
                paymentMethodId: methodId,
                totalAmount: viewModel.formattedTotal,
                onPaymentConfirmed: { _ in
                    showTransferSmsSheet = false
                    if let createdOrder = viewModel.createdOrder {
                        startOrderTracking(for: createdOrder)
                    }
                    viewModel.clearCart()
                    showOrderConfirmation = true
                },
                onGoToManualFlow: { paymentResult in
                    preInitiatedPaymentResult = paymentResult
                    showTransferSmsSheet = false
                    showBankTransferSheet = true
                },
                onDismiss: {
                    showTransferSmsSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func ordersFromCartCover() -> some View {
        NavigationStack {
            OrderListView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showOrdersFromCart = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
        }
    }

    private func ensureSelectedCurrencyIsValid() {
        if let currentMethod = selectedPaymentMethod,
            !paymentMethodSupportsCurrency(
                currentMethod.currency,
                currencyCode: selectedCurrency.rawValue
            )
        {
            selectedPaymentMethod = nil
        }
        normalizeDeliveryFeePaymentMode()
    }

    private func paymentMethodSupportsCurrency(_ methodCurrency: String, currencyCode: String)
        -> Bool
    {
        let uppercased = methodCurrency.uppercased()
        if uppercased.contains("BOTH") {
            return true
        }
        return uppercased.contains(currencyCode.uppercased())
    }

    private var shouldShowCashCUPDeliveryToggle: Bool {
        selectedCurrency == .USD && viewModel.fulfillmentMode == .delivery
    }

    private func normalizeDeliveryFeePaymentMode() {
        if !shouldShowCashCUPDeliveryToggle {
            viewModel.deliveryFeePaymentMode = .sameCurrency
        }
    }

    // MARK: - Cart Gradient Background
    private var cartGradientBackground: some View {
        CartStyle.background(colorScheme)
    }

    private var cartAccent: Color { CartStyle.ink(colorScheme) }

    private var showsCheckoutDock: Bool {
        guard !viewModel.cartItems.isEmpty else { return false }
        if case .loading = viewModel.state { return false }
        if case .error = viewModel.state { return false }
        return true
    }

    private var displayItemCount: Int {
        cartDisplayEntries.reduce(0) { count, entry in
            switch entry.kind {
            case .single(let item): return count + item.quantity
            case .combo(let primary, _): return count + primary.quantity
            }
        }
    }

    private var cartShopName: String {
        let shops = Set(viewModel.cartItems.map(\.shop).filter { !$0.isEmpty })
        return shops.count == 1 ? (shops.first ?? "Tu selección") : "Tu selección"
    }

    // MARK: - Payment Method Selector
    private var paymentMethodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { showPaymentMethodPicker = true }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(CartStyle.inset(colorScheme))
                        paymentMethodIcon
                    }
                    .frame(width: 46, height: 46)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedPaymentMethod == nil ? "¿Cómo prefieres pagar?" : "Pagar con")
                            .font(selectedPaymentMethod == nil ? .subheadline.weight(.semibold) : .caption)
                            .foregroundStyle(selectedPaymentMethod == nil ? .primary : .secondary)
                        Text(selectedPaymentMethod?.name ?? "Elige un método de pago")
                            .font(selectedPaymentMethod == nil ? .caption : .subheadline.weight(.semibold))
                            .foregroundStyle(selectedPaymentMethod == nil ? .secondary : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if viewModel.isLoadingPaymentMethods {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(cartAccent)
                    }
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.hasMultipleBranches || viewModel.isLoadingPaymentMethods || viewModel.isRefreshingCart)
            .modifier(CartSurface())
            .accessibilityLabel(selectedPaymentMethod.map { "Método de pago: \($0.name). Cambiar" } ?? "Elegir método de pago")

            if !viewModel.isLoadingPaymentMethods && filteredPaymentMethods.isEmpty && !viewModel.hasMultipleBranches {
                VStack(alignment: .leading, spacing: 8) {
                    Text(availablePaymentMethods.isEmpty
                         ? "No pudimos cargar métodos de pago. Intenta de nuevo."
                         : "Esta tienda no tiene métodos de pago en \(selectedCurrency.rawValue). Cambia la moneda arriba para continuar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if availablePaymentMethods.isEmpty {
                        Button("Volver a cargar", action: viewModel.loadPaymentMethods)
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 4)
            }

            if shouldShowCashKycBanner {
                cashKycInfoCard
            } else if isLoadingCashKycStatus {
                cashKycLoadingCard
            }
        }
    }

    @ViewBuilder
    private var paymentMethodIcon: some View {
        if let method = selectedPaymentMethod {
            switch method.imageType {
            case .systemIcon(let icon):
                Image(systemName: icon).font(.title3).foregroundStyle(cartAccent)
            case .assetImage(let name):
                Image(name).resizable().scaledToFit().padding(10)
            case .url:
                Image(systemName: "creditcard").font(.title3).foregroundStyle(cartAccent)
            }
        } else {
            Image(systemName: "creditcard").font(.title3).foregroundStyle(cartAccent)
        }
    }

    // MARK: - Process Payment
    private func processPayment() {
        // Validaciones iniciales
        if viewModel.cartItems.isEmpty {
            paymentAlertMessage = "No hay productos en el carrito."
            showPaymentAlert = true
            return
        }

        // La tienda pausó los pedidos: el backend los rechazaría con
        // BRANCH_NOT_ACCEPTING_ORDERS, así que se avisa antes de pedir biometría.
        if !viewModel.branchAcceptingOrders {
            paymentAlertMessage = BranchOrderingMessages.notAcceptingOrdersAlert
            showPaymentAlert = true
            return
        }

        guard let paymentMethod = selectedPaymentMethod else {
            paymentAlertMessage = "Por favor selecciona un método de pago."
            showPaymentAlert = true
            return
        }

        // Autenticación Biométrica (FaceID / TouchID)
        authenticateAndPay(paymentMethod: paymentMethod)
    }

    private func authenticateAndPay(paymentMethod: PaymentMethod) {
        let context = LAContext()
        var error: NSError?

        // Verificar si el dispositivo soporta biometría
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason =
                "Confirma tu identidad para realizar el pago de \(viewModel.formattedTotal)"

            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // ✅ Éxito: Sonido, Haptic y Proceder
                        playSuccessFeedback()
                        executePaymentProcessing(paymentMethod: paymentMethod)
                    } else {
                        // ❌ Fallo o Cancelación — mostrar mensaje al usuario
                        let message: String
                        if let laError = authenticationError as? LAError {
                            switch laError.code {
                            case .userCancel, .appCancel:
                                message = "Autenticación cancelada."
                            case .biometryLockout:
                                message = "Face ID bloqueado por demasiados intentos. Desbloquea el dispositivo e intenta de nuevo."
                            default:
                                message = "No se pudo verificar tu identidad. Intenta de nuevo."
                            }
                        } else {
                            message = "No se pudo verificar tu identidad. Intenta de nuevo."
                        }
                        paymentAlertMessage = message
                        showPaymentAlert = true
                    }
                }
            }
        } else {
            // Si no hay biometría disponible, proceder directamente (o pedir PIN si implementáramos eso)
            executePaymentProcessing(paymentMethod: paymentMethod)
        }
    }

    private func playSuccessFeedback() {
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // System Sound (Simular el 'Ding' de confirmación)
        // 1407: System Payment Success / Confirm
        AudioServicesPlaySystemSound(1407)
    }

    private func executePaymentProcessing(paymentMethod: PaymentMethod) {
        let backendMethod = viewModel.paymentMethods.first { $0.id == paymentMethod.id }

        // Wallet → verificar saldo antes de crear el pedido
        if backendMethod?.method.lowercased() == "wallet", let method = backendMethod {
            isLoadingPayment = true
            Task {
                do {
                    let (hasSufficient, available) = try await viewModel.checkWalletBalance(
                        for: method,
                        requiredAmount: viewModel.total,
                        selectedCurrency: selectedCurrency.rawValue
                    )
                    await MainActor.run {
                        isLoadingPayment = false
                        if hasSufficient {
                            createOrderWithPaymentMethod(paymentMethod.id)
                        } else {
                            let currencyLabel = selectedCurrency.rawValue
                            paymentAlertMessage =
                                "Saldo insuficiente en tu wallet. Tienes \(String(format: "%.2f", available)) \(currencyLabel) y el pedido requiere \(String(format: "%.2f", viewModel.total)) \(currencyLabel)."
                            showPaymentAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        isLoadingPayment = false
                        paymentAlertMessage =
                            "No se pudo verificar el saldo: \(error.localizedDescription)"
                        showPaymentAlert = true
                    }
                }
            }
            return
        }

        // Todos los demás métodos (incluyendo QvaPay): solo crear el pedido.
        // El pago se completa desde la pantalla de detalle del pedido.
        createOrderWithPaymentMethod(paymentMethod.id)
    }

    private var selectedBackendPaymentMethod: PaymentMethodModel? {
        guard let selectedPaymentMethod else { return nil }
        return viewModel.paymentMethods.first { $0.id == selectedPaymentMethod.id }
    }

    private var isSelectedCashMethod: Bool {
        if let selectedPaymentMethod, isCashPaymentMethod(selectedPaymentMethod) {
            return true
        }

        guard let backendMethod = selectedBackendPaymentMethod else { return false }
        return isCashPaymentMethod(backendMethod)
    }

    private var shouldShowCashKycBanner: Bool {
        isSelectedCashMethod && cashKycStatusSnapshot?.allowCash != true
    }

    private var cashKycInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(cartAccent.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(cartAccent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Verifica tu identidad para pagar en efectivo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(cashKycBannerMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button(action: {
                showAccountCashKycSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                    Text("Verificar mi identidad")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(cartAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cartAccent.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CartStyle.surface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cartAccent.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private var cashKycLoadingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(cartAccent)

            Text("Consultando tu verificación para efectivo…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CartStyle.surface(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cartAccent.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var cashKycBannerMessage: String {
        let prefix =
            "Para pagar en efectivo necesitas activar tu verificacion KYC. Si no lo haces, el negocio podria cancelar el pedido al revisarlo. Solo te tomara unos segundos."

        guard let snapshot = cashKycStatusSnapshot else {
            return prefix
        }

        switch snapshot.kycEvalStatus {
        case .submitted, .needsReview:
            return
                "Tu KYC todavia esta en revision. Mientras no quede activo, el negocio podria cancelar el pedido si detecta que no esta listo."
        default:
            return prefix
        }
    }

    private func refreshCashKycStatusBanner() {
        guard isSelectedCashMethod else {
            isLoadingCashKycStatus = false
            cashKycStatusSnapshot = nil
            return
        }

        guard let jwt = AuthManager.shared.getAccessToken() else {
            isLoadingCashKycStatus = false
            cashKycStatusSnapshot = nil
            return
        }

        isLoadingCashKycStatus = true

        Task {
            defer {
                Task { @MainActor in
                    isLoadingCashKycStatus = false
                }
            }

            do {
                let status = try await paymentRepository.globalCashKycStatus(jwt: jwt)
                await MainActor.run {
                    cashKycStatusSnapshot = status
                }
            } catch {
                await MainActor.run {
                    cashKycStatusSnapshot = nil
                }
            }
        }
    }

    private func isCashPaymentMethod(_ method: PaymentMethodModel) -> Bool {
        let methodValue = method.method.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let codeValue = method.code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let idValue = method.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nameValue = method.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if methodValue == "cash" || methodValue.contains("cash") || methodValue.contains("efectivo") {
            return true
        }

        if codeValue.contains("cash") || codeValue.contains("efectivo") {
            return true
        }

        if idValue.contains("cash") || idValue.contains("efectivo") {
            return true
        }

        return nameValue.contains("cash") || nameValue.contains("efectivo")
    }

    private func isCashPaymentMethod(_ method: PaymentMethod) -> Bool {
        let idValue = method.id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nameValue = method.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let descriptionValue = method.description.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if idValue == "cash" || idValue == "cash_usd" {
            return true
        }

        if idValue.contains("cash") || idValue.contains("efectivo") {
            return true
        }

        if nameValue.contains("cash") || nameValue.contains("efectivo") {
            return true
        }

        return descriptionValue.contains("cash") || descriptionValue.contains("efectivo")
    }

    private func evaluateCashAvailabilityForCheckout(
        paymentMethod: PaymentMethod,
        backendMethod: PaymentMethodModel
    ) {
        isLoadingPayment = true
        Task {
            defer { Task { @MainActor in isLoadingPayment = false } }

            guard let jwt = await MainActor.run(body: { AuthManager.shared.getAccessToken() })
            else {
                await MainActor.run {
                    paymentAlertMessage = "No hay sesión activa."
                    showPaymentAlert = true
                }
                return
            }

            guard let merchantId = await MainActor.run(body: { viewModel.cashKycMerchantId }) else {
                // Sin contexto de merchant, mantener compatibilidad con flujo checkout actual.
                await MainActor.run {
                    startCashPaymentWithKyc(
                        paymentMethod: paymentMethod, backendMethod: backendMethod)
                }
                return
            }

            let branchId = await MainActor.run(body: { viewModel.cashKycBranchId })

            do {
                // Nuevo KYC global: si ya está aprobado, reutilizar en checkout automáticamente.
                if let globalStatus = try? await paymentRepository.globalCashKycStatus(jwt: jwt),
                    globalStatus.allowCash
                {
                    await MainActor.run {
                        if !globalStatus.appCoversCash {
                            paymentAlertMessage =
                                "Pago en efectivo permitido sin cobertura de la app."
                            showPaymentAlert = true
                        }
                        createOrderWithPaymentMethod(paymentMethod.id)
                    }
                    return
                }

                // Política de merchant: si no requiere KYC o efectivo permitido sin cobertura, continuar normal.
                let policy = try await paymentRepository.cashKycPolicyByMerchant(
                    merchantId: merchantId,
                    branchId: branchId,
                    jwt: jwt
                )
                if policy.allowCash {
                    await MainActor.run {
                        if !policy.appCoversCash {
                            paymentAlertMessage =
                                "Pago en efectivo permitido sin cobertura de la app."
                            showPaymentAlert = true
                        }
                        createOrderWithPaymentMethod(paymentMethod.id)
                    }
                    return
                }

                // Merchant requiere KYC: revisar reusable por cuenta+merchant.
                let status = try await paymentRepository.cashKycStatusByAccount(
                    merchantId: merchantId,
                    branchId: branchId,
                    jwt: jwt
                )

                if status.allowCash {
                    await MainActor.run {
                        if !status.appCoversCash {
                            paymentAlertMessage =
                                "Pago en efectivo permitido sin cobertura de la app."
                            showPaymentAlert = true
                        }
                        createOrderWithPaymentMethod(paymentMethod.id)
                    }
                } else {
                    // No reusable: fallback al flujo checkout con evidencia por paymentAttempt.
                    await MainActor.run {
                        startCashPaymentWithKyc(
                            paymentMethod: paymentMethod, backendMethod: backendMethod)
                    }
                }
            } catch {
                // Fallback seguro para no romper checkout si falla account-level.
                await MainActor.run {
                    startCashPaymentWithKyc(
                        paymentMethod: paymentMethod, backendMethod: backendMethod)
                }
            }
        }
    }

    private func startCashPaymentWithKyc(
        paymentMethod: PaymentMethod,
        backendMethod: PaymentMethodModel
    ) {
        isLoadingPayment = true

        viewModel.createOrderAndInitiatePayment(
            paymentMethodId: backendMethod.id,
            includeDeliveryFee: viewModel.includeDeliveryFeeInAppPayment
        ) { result in
            Task { @MainActor in
                self.isLoadingPayment = false
                switch result {
                case .success((let order, let paymentResult)):
                    self.cashKycFlowContext = CashKycFlowContext(
                        id: paymentResult.paymentAttempt.id,
                        orderId: order.id,
                        paymentAttempt: paymentResult.paymentAttempt,
                        paymentMethodDisplayName: paymentMethod.name,
                        createdOrder: order
                    )
                case .failure(let error):
                    self.paymentAlertMessage = orderCreationFailureMessage(
                        error, prefix: "No se pudo iniciar el flujo KYC")
                    self.showPaymentAlert = true
                }
            }
        }
    }

    private func handleCashKycApproved(_ context: CashKycFlowContext) {
        cashKycFlowContext = nil
        if let createdOrder = context.createdOrder {
            startOrderTracking(for: createdOrder)
            viewModel.clearCart()
            showOrderConfirmation = true
        } else {
            paymentAlertMessage = "Verificación completada. Ya puedes pagar en efectivo."
            showPaymentAlert = true
        }
    }

    private func handleCashKycBlocked(message: String, suggestChangeMethod: Bool) {
        cashKycFlowContext = nil
        paymentAlertMessage = message
        showPaymentAlert = true

        guard suggestChangeMethod else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            selectedPaymentMethod = nil
            showPaymentMethodPicker = true
        }
    }

    // MARK: - Create Order
    /// Texto de la alerta cuando falla la creación del pedido. Si la tienda pausó los
    /// pedidos se muestra ese aviso tal cual, en vez de un error genérico con prefijo.
    private func orderCreationFailureMessage(_ error: Error, prefix: String) -> String {
        if let orderError = error as? CreateOrderError, orderError.isBranchNotAcceptingOrders {
            return orderError.localizedDescription
        }
        return "\(prefix): \(error.localizedDescription)"
    }

    private func createOrderWithPaymentMethod(
        _ paymentMethodId: String, paymentIntentId: String? = nil
    ) {
        isLoadingPayment = true

        viewModel.createOrder(
            paymentMethod: paymentMethodId,
            paymentIntentId: paymentIntentId
        ) { [self] result in
            Task { @MainActor in
                self.isLoadingPayment = false

                switch result {
                case .success(let order):
                    print("✅ Pedido creado: \(order.orderNumber)")
                    self.startOrderTracking(for: order)

                    // Limpiar carrito
                    self.viewModel.clearCart()

                    // Mostrar confirmación
                    self.showOrderConfirmation = true

                case .failure(let error):
                    print("❌ Error creando pedido: \(error.localizedDescription)")
                    self.paymentAlertMessage = orderCreationFailureMessage(
                        error, prefix: "Error al crear el pedido")
                    self.showPaymentAlert = true
                }
            }
        }
    }

    @ViewBuilder
    private var cartContent: some View {
        if case .loading = viewModel.state {
            loadingView
        } else if case .error(let message) = viewModel.state {
            errorView(message: message)
        } else if viewModel.cartItems.isEmpty {
            emptyCartView
        } else {
            populatedCartView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView().controlSize(.large).tint(cartAccent)
            Text("Preparando tu carrito…")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(cartAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.6))
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Reintentar") {
                viewModel.loadCart()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(cartAccent)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populatedCartView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                CartHeroHeader(count: displayItemCount, shop: cartShopName)

                VStack(spacing: 12) {
                    HStack {
                        CartSectionHeading(number: "01", title: "Tu selección")
                        Button("Añadir más", action: { dismiss() })
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(cartAccent)
                            .frame(minHeight: 44)
                            .buttonStyle(.plain)
                    }
                    cartItemsPanel
                    if viewModel.hasMultipleBranches { multipleBranchesBanner }
                    storeClosedBanner
                }

                VStack(alignment: .leading, spacing: 14) {
                    CartSectionHeading(number: "02", title: "A tu manera")
                    VStack(spacing: 0) {
                        fulfillmentSelectorCard
                        if viewModel.branchSchedule != nil {
                            Divider().padding(.horizontal, 16)
                            scheduledOrderCard
                        }
                    }
                    .modifier(CartSurface())
                }

                VStack(alignment: .leading, spacing: 14) {
                    CartSectionHeading(number: "03", title: "Pago y resumen")
                    paymentMethodSelector
                    priceBreakdown
                }

                if !viewModel.hasWatchedAds && viewModel.potentialSavings > 0 {
                    promotionSavingsCard
                }
                if viewModel.isLoadingSuggestions || !viewModel.suggestedProducts.isEmpty {
                    suggestedProductsSection
                        .disabled(viewModel.isRefreshingCart || viewModel.isCreatingOrder)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var cartItemsPanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(cartDisplayEntries.enumerated()), id: \.element.id) { index, entry in
                cartEntryView(entry)
                    .disabled(viewModel.isRefreshingCart || viewModel.isCreatingOrder)
                if index < cartDisplayEntries.count - 1 {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .modifier(CartSurface())
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { cartItemsCardFrame = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, frame in cartItemsCardFrame = frame }
            }
        }
    }

    @ViewBuilder
    private func cartEntryView(_ entry: CartDisplayEntry) -> some View {
        switch entry.kind {
        case .single(let item):
            CartItemCard(
                item: item,
                selectedCurrency: selectedCurrency.rawValue,
                onIncrement: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.incrementQuantity(cartItemId: item.id)
                    }
                },
                onDecrement: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.decrementQuantity(cartItemId: item.id)
                    }
                },
                onRemove: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.removeFromCart(cartItemId: item.id)
                    }
                }
            )
        case .combo(let primaryItem, let components):
            ComboCartCard(
                primaryItem: primaryItem,
                components: components,
                selectedCurrency: selectedCurrency.rawValue,
                onIncrement: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.incrementQuantity(cartItemId: primaryItem.id)
                    }
                },
                onDecrement: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.decrementQuantity(cartItemId: primaryItem.id)
                    }
                },
                onRemove: {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.removeFromCart(cartItemId: primaryItem.id)
                    }
                }
            )
        }
    }

    private func startOrderTracking(for order: CreatedOrder) {
        if OrderManager.shared.currentOrder?.id == order.id {
            return
        }

        let userLocationManager = UserLocationManager.shared
        let deliveryCoordinate: CLLocationCoordinate2D
        if let selectedAddress = viewModel.selectedAddress {
            deliveryCoordinate = CLLocationCoordinate2D(
                latitude: selectedAddress.latitude,
                longitude: selectedAddress.longitude
            )
        } else if let userLocation = userLocationManager.userLocation {
            deliveryCoordinate = userLocation
        } else {
            deliveryCoordinate = CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666)
        }

        let restaurantCoordinate = CLLocationCoordinate2D(
            latitude: deliveryCoordinate.latitude + 0.0025,
            longitude: deliveryCoordinate.longitude - 0.0025
        )

        let products = order.items.map { item in
            ActiveOrder.OrderProduct(
                id: item.productId,
                name: item.name,
                imageUrl: item.imageUrl,
                quantity: item.quantity,
                price: item.price
            )
        }

        OrderManager.shared.startRealtimeOrder(
            orderId: order.id,
            products: products,
            totalAmount: order.total,
            currency: order.currency,
            deliveryLocation: order.deliveryStreet,
            deliveryCoordinates: deliveryCoordinate,
            restaurantLocation: order.branchName,
            restaurantCoordinates: restaurantCoordinate,
            paymentMethod: order.paymentMethod,
            storeImageUrl: order.branchImageUrl,
            userAvatarUrl: AuthManager.shared.currentUser?.avatarUrl
        )
    }

    // MARK: - Generate Payment Link (LEGACY - NEEDS UPDATE)
    // TODO: Actualizar para usar el nuevo flujo de pagos con initiatePayment
    private func generatePaymentLink() {
        isLoadingPayment = true

        // Este método necesita ser actualizado para usar el nuevo sistema de pagos
        print("⚠️ generatePaymentLink() necesita ser actualizado al nuevo sistema")

        isLoadingPayment = false
        paymentAlertMessage = "Esta funcionalidad está siendo actualizada al nuevo sistema de pagos"
        showPaymentAlert = true

        /* CÓDIGO LEGACY - COMENTADO
        // Convertir el total a centavos
        let amountInCents = Int(viewModel.total * 100)
        
        print("🔗 Generando Payment Link")
        print("💰 Monto: \(amountInCents) centavos (\(viewModel.formattedTotal))")
        
        paymentRepository.createPaymentLink(
            amount: amountInCents,
            currency: "usd",
            metadata: [
                "cart_items": String(viewModel.totalItems),
                "subtotal": String(format: "%.2f", viewModel.subtotal),
                "delivery_fee": String(format: "%.2f", viewModel.deliveryFee)
            ]
        ) { [self] result in
            Task { @MainActor in
                self.isLoadingPayment = false
        
                switch result {
                case .success(let paymentLinkURL):
                    print("✅ Payment Link generado exitosamente")
                    self.generatedPaymentLink = paymentLinkURL
                    self.showPaymentLinkSheet = true
        
                case .failure(let error):
                    print("❌ Error generando Payment Link: \(error.localizedDescription)")
                    self.paymentAlertMessage = "Error al generar el link de pago: \(error.localizedDescription)"
                    self.showPaymentAlert = true
                }
            }
        }
        */
    }

    // MARK: - Stripe Payment (LEGACY - NEEDS UPDATE)
    // TODO: Actualizar para usar el nuevo flujo de pagos con initiatePayment
    private func initiateStripePayment() {
        isLoadingPayment = true

        // Este método necesita ser actualizado para usar el nuevo sistema de pagos
        print("⚠️ initiateStripePayment() necesita ser actualizado al nuevo sistema")

        isLoadingPayment = false
        paymentAlertMessage = "Esta funcionalidad está siendo actualizada al nuevo sistema de pagos"
        showPaymentAlert = true

        /* CÓDIGO LEGACY - COMENTADO
        // Convertir el total a centavos (Stripe maneja montos en centavos)
        let amountInCents = Int(viewModel.total * 100)
        
        print("💳 Iniciando pago con Stripe")
        print("💰 Monto: \(amountInCents) centavos (\(viewModel.formattedTotal))")
        
        // Verificar si estamos en modo mock
        if StripeConfig.useMockData {
            print("🧪 Usando MOCK MODE - llamando directamente a Stripe API (solo para testing)")
        
            // Crear PaymentIntent directamente con Stripe API (SOLO PARA TESTING)
            paymentRepository.createPaymentIntentDirectly(
                amount: amountInCents,
                currency: "usd"
            ) { [self] result in
                Task { @MainActor in
                    self.isLoadingPayment = false
        
                    switch result {
                    case .success(let response):
                        print("✅ [MOCK MODE] PaymentIntent creado exitosamente")
                        self.configurePaymentSheet(response: response)
        
                    case .failure(let error):
                        print("❌ [MOCK MODE] Error creando PaymentIntent: \(error.localizedDescription)")
                        self.paymentAlertMessage = "Error al iniciar el pago: \(error.localizedDescription)"
                        self.showPaymentAlert = true
                    }
                }
            }
        } else {
            print("🏭 Usando modo PRODUCCIÓN - llamando al backend")
        
            // Crear PaymentIntent en el backend (PRODUCCIÓN)
            paymentRepository.createPaymentIntent(
                amount: amountInCents,
                currency: "usd",
                customerEmail: AuthManager.shared.currentUser?.email ?? "",
                metadata: [
                    "cart_items": String(viewModel.totalItems),
                    "subtotal": String(format: "%.2f", viewModel.subtotal),
                    "delivery_fee": String(format: "%.2f", viewModel.deliveryFee)
                ]
            ) { [self] result in
                Task { @MainActor in
                    self.isLoadingPayment = false
        
                    switch result {
                    case .success(let response):
                        print("✅ PaymentIntent creado exitosamente")
                        self.configurePaymentSheet(response: response)
        
                    case .failure(let error):
                        print("❌ Error creando PaymentIntent: \(error.localizedDescription)")
                        self.paymentAlertMessage = "Error al iniciar el pago: \(error.localizedDescription)"
                        self.showPaymentAlert = true
                    }
                }
            }
        }
        */
    }

    private func configurePaymentSheet(response: PaymentIntentResponse) {
        // Configurar Stripe con la publishable key
        STPAPIClient.shared.publishableKey = response.publishableKey

        // Configurar PaymentSheet
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Llego"

        // Solo configurar customer si no estamos en modo mock
        if !StripeConfig.useMockData && response.customer != "cus_mock" {
            // Configurar customer (solo en producción con backend)
            configuration.customer = .init(
                id: response.customer,
                ephemeralKeySecret: response.ephemeralKey
            )
            print("✅ Customer configurado: \(response.customer)")
        } else {
            print("🧪 [MOCK MODE] Omitiendo configuración de Customer")
        }

        // Permitir métodos de pago diferidos (como cuentas bancarias)
        configuration.allowsDelayedPaymentMethods = true

        // Configurar URL de retorno para autenticación
        configuration.returnURL = StripeConfig.returnURL

        // MARK: - Appearance (Opcional - personalizar colores)
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor(cartAccent)
        appearance.colors.background = UIColor(Color.white)
        appearance.cornerRadius = 16.0
        configuration.appearance = appearance

        // Crear PaymentSheet
        self.paymentSheet = PaymentSheet(
            paymentIntentClientSecret: response.paymentIntent,
            configuration: configuration
        )

        print("✅ PaymentSheet configurado correctamente")
        print("   PaymentIntent: \(response.paymentIntent.prefix(20))...")
        if StripeConfig.enableInstallments {
            print("   💳 Pagos a plazos habilitados (se mostrarán si son elegibles)")
        }

        // Mostrar PaymentSheet automáticamente
        presentPaymentSheet()
    }

    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else {
            print("⚠️ PaymentSheet no está configurado")
            return
        }

        // Obtener el UIViewController actual
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        else {
            print("❌ No se pudo obtener el rootViewController")
            return
        }

        // Encontrar el viewController presentado más reciente
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }

        // Presentar PaymentSheet
        paymentSheet.present(from: topViewController) { [self] paymentResult in
            Task { @MainActor in
                self.handlePaymentResult(paymentResult)
            }
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult) {
        self.paymentResult = result

        switch result {
        case .completed:
            print("✅ Pago completado exitosamente")

            // Crear pedido real después del pago exitoso
            createOrderWithPaymentMethod("credit_card")

        case .canceled:
            print("⚠️ Pago cancelado por el usuario")
            paymentAlertMessage = "Pago cancelado. Puedes intentar nuevamente cuando estés listo."
            showPaymentAlert = true

        case .failed(let error):
            print("❌ Pago fallido: \(error.localizedDescription)")
            paymentAlertMessage = "Error al procesar el pago: \(error.localizedDescription)"
            showPaymentAlert = true
        }
    }

    // MARK: - Flying Particles Overlay
    private var flyingParticlesOverlay: some View {
        GeometryReader { geo in
            let containerOrigin = geo.frame(in: .global).origin
            ZStack {
                ForEach(flyingParticles) { particle in
                    // Convert global positions to local container coordinates
                    let localParticle = FlyingParticle(
                        id: particle.id,
                        imageUrl: particle.imageUrl,
                        source: CGPoint(
                            x: particle.source.x - containerOrigin.x,
                            y: particle.source.y - containerOrigin.y
                        ),
                        destination: CGPoint(
                            x: particle.destination.x - containerOrigin.x,
                            y: particle.destination.y - containerOrigin.y
                        )
                    )
                    FlyingParticleView(particle: localParticle) {
                        flyingParticles.removeAll { $0.id == particle.id }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .zIndex(999)
    }

    // MARK: - Suggested Products Section
    private var suggestedProductsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("¿Algo más para disfrutar?")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(cartAccent)
                Text("Ideas que van bien con tu selección")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            if viewModel.isLoadingSuggestions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(alignment: .leading, spacing: 0) {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 140, height: 140)
                                    .shimmer()
                                VStack(alignment: .leading, spacing: 6) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 11)
                                        .shimmer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 60, height: 13)
                                        .shimmer()
                                }
                                .padding(10)
                            }
                            .frame(width: 140)
                            .background(CartStyle.surface(colorScheme))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            } else if !viewModel.suggestedProducts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.suggestedProducts) { product in
                            RecommendedProductCard(
                                product: product,
                                onAdd: { buttonFrame in
                                    // Optimistic UI update — no backend reload
                                    viewModel.optimisticallyAdd(product: product)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                                    // Launch fly-to-cart animation
                                    let destination = CGPoint(
                                        x: cartItemsCardFrame.midX,
                                        y: cartItemsCardFrame.minY + 28
                                    )
                                    let source = CGPoint(
                                        x: buttonFrame.midX,
                                        y: buttonFrame.midY
                                    )
                                    let particle = FlyingParticle(
                                        id: UUID(),
                                        imageUrl: product.imageUrl,
                                        source: source,
                                        destination: destination
                                    )
                                    if !reduceMotion { flyingParticles.append(particle) }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("No se encontraron recomendaciones")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(CartStyle.surface(colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var emptyCartView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 38)
                        .fill(Color.llegoAccent.opacity(0.3))
                        .frame(width: 140, height: 150)
                        .rotationEffect(.degrees(-8))
                    Image(systemName: "bag")
                        .font(.system(size: 58, weight: .light))
                        .foregroundStyle(cartAccent)
                    Image(systemName: "sparkle")
                        .font(.system(size: 25))
                        .foregroundStyle(cartAccent)
                        .offset(x: 64, y: -65)
                }
                .padding(.bottom, 10)
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Todo lo bueno\nempieza por elegir.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .tracking(-1)
                        .foregroundStyle(cartAccent)
                    Text("Tu carrito está esperando tus favoritos.\nEncuentra algo que te encante.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                Button(action: { dismiss() }) {
                    Label("Explorar productos", systemImage: "arrow.right")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 17)
                        .frame(maxWidth: .infinity)
                        .background(Color.llegoPrimary, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                Button("Ver mis pedidos", action: openMyOrdersFromCart)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(cartAccent)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Scheduled Order

    private var scheduledOrderCard: some View {
        HStack(spacing: 4) {
            Button(action: { showScheduledOrderPicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(cartAccent)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.scheduledFor.map(formattedScheduledDate) ?? "¿Lo prefieres más tarde?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(viewModel.scheduledFor == nil ? "Programa tu pedido para hoy o mañana" : "Pedido programado · cambiar hora")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if viewModel.scheduledFor == nil {
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 16)
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if viewModel.scheduledFor != nil {
                Button(action: { viewModel.scheduledFor = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancelar programación del pedido")
            }
        }
        .padding(.trailing, 8)
    }

    private func formattedScheduledDate(_ date: Date) -> String {
        let havana = TimeZone(identifier: "America/Havana") ?? .current
        let cal = Calendar.current
        let dayLabel = cal.isDateInToday(date) ? "Hoy" : "Mañana"
        let formatter = DateFormatter()
        formatter.timeZone = havana
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "es_CU")
        return "\(dayLabel) a las \(formatter.string(from: date))"
    }

    // MARK: - Fulfillment Selector

    private var fulfillmentSelectorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isStorePickupEnabled && viewModel.isPickupAvailableForCurrentCart {
                HStack(spacing: 8) {
                    fulfillmentOptionButton(mode: .delivery, icon: "bicycle", title: "A domicilio")
                    fulfillmentOptionButton(mode: .pickup, icon: "bag", title: "Recoger en tienda")
                }
            }

            if viewModel.fulfillmentMode == .pickup {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "storefront")
                        .font(.title3)
                        .foregroundStyle(cartAccent)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedPickup?.branchName ?? cartShopName)
                            .font(.subheadline.weight(.semibold))
                        Text(viewModel.selectedPickup?.address ?? "La tienda te indicará el punto de recogida")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Recogida sin coste de envío")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(cartAccent)
                    }
                }
            } else {
                Button(action: { showAddressPicker = true }) {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.title3)
                            .foregroundStyle(cartAccent)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(needsDeliveryAddress ? "¿Dónde te lo llevamos?" : deliveryAddressTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(needsDeliveryAddress ? "Elige una dirección de entrega" : deliveryAddressDetail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Elegir o cambiar la dirección de entrega")
            }
        }
        .padding(16)
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: viewModel.fulfillmentMode)
    }

    private var needsDeliveryAddress: Bool {
        viewModel.selectedAddress == nil && (!locationManager.hasLocation || locationManager.isAutoFallback)
    }

    private var deliveryAddressTitle: String {
        guard let address = viewModel.selectedAddress else { return "Entregar en tu ubicación" }
        return address.label.isEmpty ? "Dirección de entrega" : address.label
    }

    private var deliveryAddressDetail: String {
        viewModel.selectedAddress?.street ?? locationManager.userAddress
    }

    private func fulfillmentOptionButton(mode: FulfillmentMode, icon: String, title: String) -> some View {
        let isSelected = viewModel.fulfillmentMode == mode
        return Button {
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { viewModel.setFulfillmentMode(mode) }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(.title3, weight: .medium))
                Text(title)
                    .font(.system(.caption, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? cartAccent : .secondary)
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(.vertical, 8)
            .background(isSelected ? Color.llegoAccent.opacity(0.18) : CartStyle.inset(colorScheme), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? cartAccent.opacity(0.45) : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var multipleBranchesBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
            Text(
                "Solo puedes pedir a una tienda a la vez. Elimina productos de otras tiendas para continuar."
            )
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    @ViewBuilder
    private var storeClosedBanner: some View {
        if !viewModel.branchAcceptingOrders {
            // Pedidos pausados por la tienda: el checkout está bloqueado.
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(BranchOrderingMessages.notAcceptingOrdersShort)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    Text(BranchOrderingMessages.notAcceptingOrdersDetail)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
            )
        } else if let status = viewModel.branchOpenStatus, !status.isOpen {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text(status.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                Spacer()
                Text("Programa tu pedido para cuando abra")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.08))
            )
        }
    }

    private func openMyOrdersFromCart() {
        showOrdersFromCart = true
    }

    private var checkoutDock: some View {
        CartCheckoutDock(
            total: viewModel.hasShowcaseItems ? "Por confirmar" : viewModel.formattedTotal,
            caption: checkoutCaption,
            title: checkoutTitle,
            isBusy: viewModel.isRefreshingCart || viewModel.isCreatingOrder || isLoadingPayment,
            isBlocked: isPlaceOrderBlocked || (selectedPaymentMethod == nil && (viewModel.isLoadingPaymentMethods || filteredPaymentMethods.isEmpty)),
            onContinue: continueCheckout)
    }

    private var checkoutTitle: String {
        if viewModel.isRefreshingCart { return "Actualizando tu carrito…" }
        if viewModel.isCreatingOrder || isLoadingPayment { return "Preparando pedido…" }
        if viewModel.hasMultipleBranches { return "Elige productos de una tienda" }
        if !viewModel.branchAcceptingOrders { return "Pedidos pausados por la tienda" }
        if selectedPaymentMethod == nil {
            return viewModel.isLoadingPaymentMethods ? "Cargando métodos de pago…" : "Elegir cómo pagar"
        }
        if viewModel.fulfillmentMode == .delivery && needsDeliveryAddress { return "Elegir dirección de entrega" }
        return selectedPaymentMethod?.id == "invoice_international" ? "Enviar factura" : "Confirmar pedido"
    }

    private var checkoutCaption: String {
        if viewModel.hasShowcaseItems { return "Precio pendiente de la tienda" }
        if viewModel.fulfillmentMode == .delivery && viewModel.deliveryFeePaymentMode == .cashCUP {
            return "Total + \(viewModel.formattedDeliveryFee) de envío al entregar"
        }
        return viewModel.fulfillmentMode == .delivery ? "Total estimado" : "Total del pedido"
    }

    private func continueCheckout() {
        guard !isPlaceOrderBlocked, !viewModel.isRefreshingCart, !viewModel.isCreatingOrder else { return }
        guard selectedPaymentMethod != nil else {
            showPaymentMethodPicker = true
            return
        }
        if viewModel.fulfillmentMode == .pickup {
            processPayment()
        } else if needsDeliveryAddress {
            // Choosing an address returns to the review screen; it never submits an order.
            showAddressPicker = true
        } else {
            showDeliveryAddressAlert = true
        }
    }

    /// El pedido no se puede hacer: hay productos de varias tiendas o la tienda pausó los pedidos.
    private var isPlaceOrderBlocked: Bool {
        viewModel.hasMultipleBranches || !viewModel.branchAcceptingOrders
    }

    private var deliveryAddressAlertMessage: String {
        if let selected = viewModel.selectedAddress {
            let title = selected.label.isEmpty ? "Dirección guardada" : selected.label
            return
                "\(title): \(selected.street)\n\n¿Deseas continuar con esta dirección o elegir otra?"
        }
        return
            "Dirección actual: \(UserLocationManager.shared.userAddress)\n\n¿Deseas continuar con esta dirección o elegir otra?"
    }

    private var priceBreakdown: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LA CUENTA, CLARITA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                Spacer()
                Image(systemName: "receipt")
            }
            .foregroundStyle(cartAccent.opacity(0.75))
            .padding(18)

            CartReceiptDivider().padding(.horizontal, 18)
            priceRow(label: "Productos", value: viewModel.hasShowcaseItems ? "Por confirmar" : viewModel.formattedSubtotal, labelWeight: .regular, valueWeight: .medium)
            serviceFeeInline

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.fulfillmentMode == .pickup ? "Recogida" : "Envío estimado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    if viewModel.isLoadingDeliveryFee && viewModel.fulfillmentMode == .delivery {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(viewModel.formattedDeliveryFee)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                }
                if viewModel.fulfillmentMode == .delivery {
                    Text(viewModel.deliveryFeeDescription)
                        .font(.caption)
                        .foregroundStyle(viewModel.deliveryFeeError != nil && viewModel.deliveryFeeEstimate == nil ? .orange : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if viewModel.deliveryFeeError != nil, let branch = viewModel.cartItems.first?.branchId {
                        Button("Volver a estimar envío") { viewModel.fetchDeliveryFeeEstimate(branchId: branch) }
                            .font(.caption.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                }
                if shouldShowCashCUPDeliveryToggle { deliveryFeePaymentPrompt }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            CartReceiptDivider().padding(.horizontal, 18)
            VStack(alignment: .leading, spacing: 8) {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) { receiptTotalLabel; receiptTotalValue }
                } else {
                    HStack(alignment: .firstTextBaseline) { receiptTotalLabel; Spacer(minLength: 8); receiptTotalValue }
                }
                if shouldShowCashCUPDeliveryToggle && viewModel.deliveryFeePaymentMode == .cashCUP {
                    Text("El envío se paga aparte: \(viewModel.formattedDeliveryFee) en efectivo al entregar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if viewModel.hasShowcaseItems {
                    Text("La tienda confirmará el precio de tu pedido personalizado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
        }
        .modifier(CartSurface())
    }

    private var receiptTotalLabel: some View {
        Text(viewModel.fulfillmentMode == .delivery ? "Total estimado" : "Total")
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(cartAccent)
    }

    private var receiptTotalValue: some View {
        Text(viewModel.hasShowcaseItems ? "Por confirmar" : viewModel.formattedTotal)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(cartAccent)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var promotionSavingsCard: some View {
        Button(action: { showAdView = true }) {
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle")
                    .font(.title2)
                    .foregroundStyle(cartAccent)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Un pequeño plan para ahorrar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Mira una promoción y ahorra \(viewModel.formattedPotentialSavings) en el servicio.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cartAccent)
            }
            .padding(16)
            .background(Color.llegoAccent.opacity(colorScheme == .dark ? 0.08 : 0.18), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opcional. Reduce el cargo de servicio después de ver la promoción")
    }

    private var orderConfirmationLocationLabel: String {
        let cartViewModel = _viewModel.wrappedValue

        if cartViewModel.fulfillmentMode.rawValue == "PICKUP" {
            if let pickup = cartViewModel.selectedPickup {
                return pickup.address ?? pickup.branchName
            }
            return "Recogida en tienda"
        }
        if let selected = cartViewModel.selectedAddress {
            return selected.street
        }
        return UserLocationManager.shared.userAddress
    }

    private func priceRow(
        label: String, value: String, labelWeight: Font.Weight, valueWeight: Font.Weight
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, weight: labelWeight))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: valueWeight))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var deliveryFeePaymentPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Quieres pagar el envío en USD o en efectivo CUP al mensajero?")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                deliveryFeeModeButton(
                    title: "Pagar en USD",
                    isSelected: viewModel.deliveryFeePaymentMode == .sameCurrency
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.deliveryFeePaymentMode = .sameCurrency
                    }
                }

                deliveryFeeModeButton(
                    title: "Efectivo CUP",
                    isSelected: viewModel.deliveryFeePaymentMode == .cashCUP
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.deliveryFeePaymentMode = .cashCUP
                    }
                }
            }
        }
    }

    private func deliveryFeeModeButton(
        title: String, isSelected: Bool, action: @escaping () -> Void
    )
        -> some View
    {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? Color.white : Color.secondary)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? Color.llegoPrimary
                                : CartStyle.inset(colorScheme)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Service Fee Inline (dentro de la tarjeta de precios)
    private var serviceFeeInline: some View {
        HStack {
            Text("Servicio (\(viewModel.serviceFeePercentage)%)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.hasShowcaseItems ? "Por confirmar" : viewModel.formattedServiceFee)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(viewModel.hasWatchedAds ? Color(.systemGreen) : .primary)
                if viewModel.hasWatchedAds {
                    Text("-\(viewModel.formattedAdSavings)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.systemGreen))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fullScreenCover(isPresented: $showAdView) {
            PromoStoriesView(
                onComplete: {
                    viewModel.activateAdDiscount()
                    showAdView = false
                },
                onClose: {
                    showAdView = false
                }
            )
        }
    }

}

#Preview {
    CartView()
}
