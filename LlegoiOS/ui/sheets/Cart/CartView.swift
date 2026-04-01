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
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var selectedCurrency: Currency = .CUP
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showPaymentMethodPicker = false
    @State private var navigateToPlans = false
    @State private var showOrdersFromCart = false

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
    @State private var pendingPaymentAfterAddressSelection = false

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
                        }
                    )
                }
                .navigationDestination(isPresented: $navigateToPlans) {
                    PlansAndPricingView()
                }
                .fullScreenCover(isPresented: $showOrdersFromCart, content: ordersFromCartCover)
        }
    }

    // MARK: - Cart Sheets Layer

    private var cartSheetsLayer: some View {
        ZStack(alignment: .top) {
            cartGradientBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)
            flyingParticlesOverlay
            cartContent
        }
        .navigationTitle("Carrito")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { cartToolbarItems }
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
                if pendingPaymentAfterAddressSelection {
                    pendingPaymentAfterAddressSelection = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { processPayment() }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Dirección de entrega", isPresented: $showDeliveryAddressAlert, titleVisibility: .visible) {
            Button("Esta dirección") { processPayment() }
            Button("Otra dirección") { pendingPaymentAfterAddressSelection = true; showAddressPicker = true }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(deliveryAddressAlertMessage)
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
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                LottieView(name: "loading").frame(width: 150, height: 150)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(gradientManager.currentAccentColor)
                Text("Preparando pago...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var cartToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if availableCurrencies.count > 1 {
                Menu {
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                    Text(selectedCurrency.rawValue)
                }
            } else {
                Text(selectedCurrency.rawValue)
            }
        }

        if !viewModel.cartItems.isEmpty {
            ToolbarItem(placement: .bottomBar) {
                bottomPaymentMethodAction
            }

            ToolbarItem(placement: .bottomBar) {
                bottomPlaceOrderAction
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
        selectedCurrency == .USD
    }

    private func normalizeDeliveryFeePaymentMode() {
        if !shouldShowCashCUPDeliveryToggle {
            viewModel.deliveryFeePaymentMode = .sameCurrency
        }
    }

    // MARK: - Cart Gradient Background
    private var cartGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.4)

            // Gradiente sutil
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.15), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.3), location: 0.4),
                    .init(
                        color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.95),
                        location: 1.0),
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Payment Method Selector
    private var paymentMethodSelector: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Método de Pago")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(gradientManager.currentAccentColor)

                Spacer()

                Button(action: {
                    showPaymentMethodPicker = true
                }) {
                    HStack(spacing: 6) {
                        Text(selectedPaymentMethod != nil ? "Cambiar" : "Seleccionar")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(gradientManager.currentAccentColor)
                }
            }

            if let method = selectedPaymentMethod {
                HStack(spacing: 16) {
                    // Icono del método
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(method.color.opacity(0.1))
                            .frame(width: 50, height: 50)

                        switch method.imageType {
                        case .systemIcon(let iconName):
                            Image(systemName: iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(method.color)
                        case .assetImage(let imageName):
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        case .url:
                            Image(systemName: "creditcard")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(method.color)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)

                        Text(method.description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Moneda
                    Text(method.currency)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(method.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(method.color.opacity(0.15))
                        .cornerRadius(8)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(method.color.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )

                if shouldShowCashKycBanner {
                    cashKycInfoCard
                } else if isLoadingCashKycStatus {
                    cashKycLoadingCard
                }
            } else {
                Button(action: {
                    showPaymentMethodPicker = true
                }) {
                    HStack {
                        Image(systemName: "creditcard")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)

                        Text("Selecciona un método de pago")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                            )
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Process Payment
    private func processPayment() {
        // Validaciones iniciales
        if viewModel.cartItems.isEmpty {
            paymentAlertMessage = "No hay productos en el carrito."
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
                        // ❌ Fallo o Cancelación
                        if let error = authenticationError as? LAError {
                            // Manejar errores específicos si es necesario
                            print("Authentication failed: \(error.localizedDescription)")
                        }
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
                        .fill(gradientManager.currentAccentColor.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.shield")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Activa tu KYC para pagar en efectivo")
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
                    Text("Hacer KYC ahora")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(gradientManager.currentAccentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(gradientManager.currentAccentColor.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(gradientManager.currentAccentColor.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private var cashKycLoadingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(gradientManager.currentAccentColor)

            Text("Consultando estado de tu KYC para efectivo...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(gradientManager.currentAccentColor.opacity(0.12), lineWidth: 1)
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
                    self.paymentAlertMessage =
                        "No se pudo iniciar el flujo KYC: \(error.localizedDescription)"
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
                    self.paymentAlertMessage =
                        "Error al crear el pedido: \(error.localizedDescription)"
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
        VStack(spacing: 20) {
            LottieView(name: "loader")
                .frame(width: 150, height: 150)
            Text("Cargando carrito...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
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
            .background(gradientManager.currentAccentColor)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populatedCartView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                cartItemsPanel

                if viewModel.hasMultipleBranches {
                    multipleBranchesBanner
                }

                priceBreakdown
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var cartItemsPanel: some View {
        VStack(spacing: 0) {
            ForEach(Array(cartDisplayEntries.enumerated()), id: \.element.id) { index, entry in
                VStack(spacing: 0) {
                    cartEntryView(entry)
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            )
                        )
                        .animation(
                            .easeInOut(duration: 0.3).delay(Double(index) * 0.05),
                            value: cartDisplayEntries.count)

                    if index < cartDisplayEntries.count - 1 {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.white
                    .onAppear {
                        cartItemsCardFrame = geo.frame(in: .global)
                    }
                    .onChange(of: cartDisplayEntries.count) { _, _ in
                        cartItemsCardFrame = geo.frame(in: .global)
                    }
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func cartEntryView(_ entry: CartDisplayEntry) -> some View {
        switch entry.kind {
        case .single(let item):
            CartItemCard(
                item: item,
                selectedCurrency: selectedCurrency.rawValue,
                onIncrement: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.incrementQuantity(cartItemId: item.id)
                    }
                },
                onDecrement: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.decrementQuantity(cartItemId: item.id)
                    }
                },
                onRemove: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.incrementQuantity(cartItemId: primaryItem.id)
                    }
                },
                onDecrement: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.decrementQuantity(cartItemId: primaryItem.id)
                    }
                },
                onRemove: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                customerEmail: "user@example.com", // TODO: Obtener email del usuario actual
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
        configuration.merchantDisplayName = StripeConfig.merchantDisplayName

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

        // MARK: - Apple Pay Configuration
        if StripeConfig.enableApplePay {
            configuration.applePay = .init(
                merchantId: StripeConfig.applePayMerchantId,
                merchantCountryCode: StripeConfig.merchantCountryCode
            )
            print("🍎 Apple Pay habilitado")
            print("   Merchant ID: \(StripeConfig.applePayMerchantId)")
            print("   Country: \(StripeConfig.merchantCountryCode)")
        }

        // Permitir métodos de pago diferidos (como cuentas bancarias)
        configuration.allowsDelayedPaymentMethods = true

        // Configurar URL de retorno para autenticación
        configuration.returnURL = StripeConfig.returnURL

        // MARK: - Appearance (Opcional - personalizar colores)
        var appearance = PaymentSheet.Appearance()
        appearance.colors.primary = UIColor(gradientManager.currentAccentColor)
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
            // Header
            HStack(alignment: .top, spacing: 10) {
                // Icono IA
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.36, green: 0.18, blue: 0.90),
                                    Color(red: 0.55, green: 0.22, blue: 0.98),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Recomendado para ti")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        if viewModel.isLoadingSuggestions {
                            ProgressView()
                                .scaleEffect(0.65)
                                .tint(.secondary)
                        }
                    }
                    Text("Seleccionado con Inteligencia Artificial")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.45, green: 0.22, blue: 0.90))
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)

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
                            .background(Color.white)
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
                                    flyingParticles.append(particle)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientManager.currentAccentColor.opacity(0.22),
                                gradientManager.currentAccentColor.opacity(0.12),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)

                Image(systemName: "cart")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            VStack(spacing: 8) {
                Text("Tu carrito está vacío")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Agrega productos para comenzar tu pedido")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)

            Button(action: openMyOrdersFromCart) {
                HStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Ver mis pedidos")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .frame(height: 44)
                .frame(maxWidth: 200)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func openMyOrdersFromCart() {
        showOrdersFromCart = true
    }

    private var bottomPaymentMethodAction: some View {
        Button(action: {
            if !viewModel.hasMultipleBranches {
                showPaymentMethodPicker = true
            }
        }) {
            HStack(spacing: 6) {
                if let method = selectedPaymentMethod {
                    switch method.imageType {
                    case .systemIcon(let iconName):
                        Image(systemName: iconName)
                            .font(.system(size: 13, weight: .semibold))
                    case .assetImage(let imageName):
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    case .url:
                        Image(systemName: "creditcard")
                            .font(.system(size: 13, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Pagar con")
                            .font(.system(size: 12, weight: .medium))
                        Text(method.name)
                            .font(.system(size: 13, weight: .bold))
                            .lineLimit(1)
                    }
                } else {
                    Image(systemName: "creditcard")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Método")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(minWidth: 140)
            .frame(height: 52)
        }
        .modifier(GlassProminentButtonModifier())
        .tint(.black)
        .disabled(viewModel.hasMultipleBranches)
        .opacity(viewModel.hasMultipleBranches ? 0.45 : 1.0)
    }

    private var bottomPlaceOrderAction: some View {
        Button(action: {
            if !viewModel.hasMultipleBranches {
                showDeliveryAddressAlert = true
            }
        }) {
            HStack(spacing: 6) {
                if selectedPaymentMethod?.id == "invoice_international" {
                    Text("Enviar factura")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                } else {
                    Text("Pedir")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(viewModel.formattedTotal)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            .frame(minWidth: 150)
            .frame(height: 52)
        }
        .modifier(GlassProminentButtonModifier())
        .tint(gradientManager.currentAccentColor)
        .disabled(viewModel.hasMultipleBranches)
        .opacity(viewModel.hasMultipleBranches ? 0.45 : 1.0)
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
        VStack(spacing: 12) {
            // Tarjeta única: Subtotal + Cargo de servicio + Envío + Total
            VStack(spacing: 0) {
                // Subtotal
                priceRow(
                    label: "Subtotal",
                    value: viewModel.formattedSubtotal,
                    labelWeight: .regular,
                    valueWeight: .medium
                )

                priceDivider

                // Cargo de servicio
                serviceFeeInline

                priceDivider

                // Envío
                HStack {
                    Text("Envío")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                    if !viewModel.deliveryFeeDescription.isEmpty {
                        Text("· \(viewModel.deliveryFeeDescription)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(
                                viewModel.deliveryFeeError != nil
                                    && viewModel.deliveryFeeEstimate == nil
                                    ? .red : Color(.tertiaryLabel)
                            )
                            .lineLimit(1)
                    }
                    Spacer()
                    if viewModel.isLoadingDeliveryFee {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.75)
                    } else {
                        Text(viewModel.formattedDeliveryFee)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 13)
                .padding(.horizontal, 16)

                if shouldShowCashCUPDeliveryToggle {
                    deliveryFeePaymentPrompt
                        .padding(.horizontal, 16)
                        .padding(.bottom, 13)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                } else {
                    Spacer()
                        .frame(height: 8)
                }

                priceDivider

                // Total
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(viewModel.formattedTotal)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding(.top, 14)
                .padding(.horizontal, 16)

                if shouldShowCashCUPDeliveryToggle,
                    viewModel.deliveryFeePaymentMode == .cashCUP
                {
                    Text("El envío se paga en efectivo CUP al entregar")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                } else {
                    Spacer()
                        .frame(height: 14)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: selectedCurrency)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

            // Incentivo para ver anuncios (solo si no ha visto)
            if !viewModel.hasWatchedAds {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Ahorra viendo una promoción")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(
                            "\(viewModel.formattedTotalWithDiscount) · ahorras \(viewModel.formattedPotentialSavings)"
                        )
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { showAdView = true }) {
                        Text("Ver")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.systemGreen)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            }

            // Productos recomendados por IA
            suggestedProductsSection
        }
    }

    private var orderConfirmationLocationLabel: String {
        if viewModel.fulfillmentMode == .pickup {
            if let pickup = viewModel.selectedPickup {
                return pickup.address ?? pickup.branchName
            }
            return "Recogida en tienda"
        }
        if let selected = viewModel.selectedAddress {
            return selected.street
        }
        return UserLocationManager.shared.userAddress
    }

    private func priceRow(
        label: String, value: String, labelWeight: Font.Weight, valueWeight: Font.Weight
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: labelWeight))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: valueWeight, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
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
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? gradientManager.currentAccentColor
                                : Color(.systemGray5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var priceDivider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.5))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    // MARK: - Service Fee Inline (dentro de la tarjeta de precios)
    private var serviceFeeInline: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Cargo de servicio")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                Text("\(viewModel.serviceFeePercentage)%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(viewModel.formattedServiceFee)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.hasWatchedAds ? Color(.systemGreen) : .primary)
                if viewModel.hasWatchedAds {
                    Text("-\(viewModel.formattedAdSavings)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.systemGreen))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .fullScreenCover(isPresented: $showAdView) {
            AdWatcherView(onComplete: {
                viewModel.activateAdDiscount()
                showAdView = false
            })
        }
    }

    // MARK: - Payment Methods Info Banner

    private var paymentMethodsInfoBanner: some View {
        Group {
            if viewModel.isLoadingPaymentMethods {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Cargando métodos de pago...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.gray.opacity(0.06))
                )
            } else if !availablePaymentMethods.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                        Text("Este negocio acepta")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availablePaymentMethods, id: \.id) { method in
                                HStack(spacing: 5) {
                                    switch method.imageType {
                                    case .systemIcon(let iconName):
                                        Image(systemName: iconName)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(method.color)
                                    case .assetImage(let imageName):
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 13, height: 13)
                                    case .url:
                                        Image(systemName: "creditcard")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(method.color)
                                    }
                                    Text(method.name)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(method.color.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(method.color.opacity(0.25), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Otros negocios pueden ofrecer métodos adicionales.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))
                            .italic()
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(gradientManager.currentAccentColor.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    gradientManager.currentAccentColor.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }

}

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    CartView()
}
