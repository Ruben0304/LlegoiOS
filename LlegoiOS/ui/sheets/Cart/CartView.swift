import AudioToolbox
import CoreLocation
import LocalAuthentication
import StripePaymentSheet
import SwiftUI

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

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Fondo gradiente sutil sincronizado
                cartGradientBackground
                    .ignoresSafeArea()
                    .animation(
                        .easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

                // Flying particles overlay for add-to-cart animation
                flyingParticlesOverlay

                if case .loading = viewModel.state {
                    VStack(spacing: 20) {
                        LottieView(name: "loader")
                            .frame(width: 150, height: 150)
                        Text("Cargando carrito...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Error State
                else if case .error(let message) = viewModel.state {
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
                // Empty Cart
                else if viewModel.cartItems.isEmpty {
                    emptyCartView
                }
                // Cart with items
                else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 12) {
                            // Tarjeta única con todos los items del carrito
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.cartItems.enumerated()), id: \.element.id) {
                                    index, item in
                                    VStack(spacing: 0) {
                                        CartItemCard(
                                            item: item,
                                            selectedCurrency: selectedCurrency.rawValue,
                                            onIncrement: {
                                                withAnimation(
                                                    .spring(response: 0.6, dampingFraction: 0.8)
                                                ) {
                                                    viewModel.incrementQuantity(cartItemId: item.id)
                                                }
                                            },
                                            onDecrement: {
                                                withAnimation(
                                                    .spring(response: 0.6, dampingFraction: 0.8)
                                                ) {
                                                    viewModel.decrementQuantity(cartItemId: item.id)
                                                }
                                            },
                                            onRemove: {
                                                withAnimation(
                                                    .spring(response: 0.6, dampingFraction: 0.8)
                                                ) {
                                                    viewModel.removeFromCart(cartItemId: item.id)
                                                }
                                            }
                                        )
                                        .transition(
                                            .asymmetric(
                                                insertion: .scale.combined(with: .opacity),
                                                removal: .scale.combined(with: .opacity)
                                            )
                                        )
                                        .animation(
                                            .easeInOut(duration: 0.3).delay(Double(index) * 0.05),
                                            value: viewModel.cartItems.count)

                                        if index < viewModel.cartItems.count - 1 {
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
                                        .onChange(of: viewModel.cartItems.count) { _, _ in
                                            cartItemsCardFrame = geo.frame(in: .global)
                                        }
                                }
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)

                            if viewModel.hasMultipleBranches {
                                multipleBranchesBanner
                            }

                            // Resumen de precios
                            priceBreakdown
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle("Carrito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            //            .modifier(NavigationBarWhiteBackground())
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
                    onDismiss: {
                        showPaymentLinkSheet = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBankTransferSheet) {
                BankTransferSheetView(
                    totalAmount: viewModel.formattedTotal,
                    onConfirm: { _ in
                        showBankTransferSheet = false
                        if let preResult = preInitiatedPaymentResult {
                            // Ya hay un paymentAttempt creado (viene del flujo Transfermóvil No-SMS)
                            // Confirmar directamente con confirmPaymentSent usando proofUrl vacío por ahora
                            // TODO: pasar la proofUrl real desde BankTransferSheetView
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
                            // Flujo normal: crear pedido con bank_transfer
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
            .sheet(isPresented: $showTransferSmsSheet) {
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
                            // Abrir sheet de transferencia manual con el attempt ya creado
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
            .sheet(isPresented: $showAddressPicker) {
                SavedAddressesView(isSelectingDeliveryAddress: true) { address in
                    viewModel.selectedAddress = address
                    if pendingPaymentAfterAddressSelection {
                        pendingPaymentAfterAddressSelection = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            processPayment()
                        }
                    }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Dirección de entrega",
                isPresented: $showDeliveryAddressAlert,
                titleVisibility: .visible
            ) {
                Button("Esta dirección") {
                    processPayment()
                }
                Button("Otra dirección") {
                    pendingPaymentAfterAddressSelection = true
                    showAddressPicker = true
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(deliveryAddressAlertMessage)
            }
            .alert("Estado del Pago", isPresented: $showPaymentAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(paymentAlertMessage)
            }
            .overlay {
                if isLoadingPayment {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            LottieView(name: "loading")
                                .frame(width: 150, height: 150)
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
            .onChange(of: viewModel.cartItems) { _, _ in
                ensureSelectedCurrencyIsValid()
            }
            .fullScreenCover(isPresented: $showOrderConfirmation) {
                OrderConfirmationView(
                    deliveryLocation: "Calle 23 #456, Vedado, La Habana",  //TODO: Usar ubicación real del usuario
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
            .fullScreenCover(isPresented: $showOrdersFromCart) {
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

    private func paymentMethodSupportsCurrency(_ methodCurrency: String, currencyCode: String) -> Bool {
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

    private func deliveryFeeModeButton(title: String, isSelected: Bool, action: @escaping () -> Void)
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
                                .stroke(gradientManager.currentAccentColor.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }

}

// MARK: - Payment Method Picker View
struct PaymentMethodPickerView: View {
    let paymentMethods: [PaymentMethod]
    @Binding var selectedMethod: PaymentMethod?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        //                        header
                        paymentList
                    }
                }
            }
            .navigationTitle("Métodos de Pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton(action: {
                        dismiss()
                    })
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Métodos de pago")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(
                "Elige la opción que prefieras. Mostramos sólo la información esencial para que la decisión sea rápida."
            )
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var paymentList: some View {
        Group {
            if paymentMethods.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No hay métodos de pago disponibles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Por favor, intenta de nuevo más tarde")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(enumeratedPaymentMethods, id: \.element.id) { pair in
                        let index = pair.offset
                        let method = pair.element
                        PaymentMethodRow(
                            method: method,
                            isSelected: selectedMethod?.id == method.id,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMethod = method
                                }
                                // Cerrar después de seleccionar
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            },
                            animationDelay: Double(index) * 0.05
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var enumeratedPaymentMethods: [(offset: Int, element: PaymentMethod)] {
        Array(paymentMethods.enumerated())
    }
}

// MARK: - Payment Method Row

struct CartItemCard: View {
    let item: CartItem
    let selectedCurrency: String
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Imagen del producto circular
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)

                if item.isShowcase && item.imageUrl.isEmpty {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                } else {
                    CachedAsyncImage(
                        url: URL(string: item.imageUrl),
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        },
                        placeholder: {
                            ProgressView()
                                .tint(Color.gray.opacity(0.6))
                                .scaleEffect(0.85)
                                .frame(width: 56, height: 56)
                        }
                    )
                }
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

            // Información del producto
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if item.isShowcase {
                    Text(item.showcaseRequestDescription ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if item.isComboComponent {
                    HStack(spacing: 6) {
                        Text(item.comboName ?? "Combo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                        if let slotName = item.comboComponentSlotName, !slotName.isEmpty {
                            Text("•")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(slotName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.shop)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(item.weight)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                // Precio y total
                if item.isShowcase {
                    HStack(spacing: 6) {
                        Text("Precio por confirmar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("•")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Cantidad: \(item.quantity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.formattedPrice(for: selectedCurrency))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("× \(item.quantity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)

                        Text("=")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(item.formattedItemTotal(for: selectedCurrency))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                if let currencyInfo = item.currencyInfoText(for: selectedCurrency) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text(currencyInfo)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(2)
                    }
                    .foregroundColor(.orange.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                    )
                }

                if !item.selectedVariants.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(item.selectedVariants, id: \.self) { variant in
                            HStack(spacing: 4) {
                                Text("\(variant.listName):")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(variant.optionName)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.primary)
                                if variant.priceAdjustment != .zero {
                                    Text(
                                        String(
                                            format: "(%@$%.2f)",
                                            variant.priceAdjustment > .zero ? "+" : "",
                                            NSDecimalNumber(decimal: variant.priceAdjustment)
                                                .doubleValue
                                        )
                                    )
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Controles compactos
            VStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }

                // Controles de cantidad
                HStack(spacing: 6) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 22)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                    }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Flying Particle Model & View

struct FlyingParticle: Identifiable {
    let id: UUID
    let imageUrl: String
    let source: CGPoint
    let destination: CGPoint
}

struct FlyingParticleView: View {
    let particle: FlyingParticle
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        let pos = currentPosition(progress: progress)

        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

            CachedAsyncImage(
                url: URL(string: particle.imageUrl),
                content: { image in
                    image.resizable().scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                },
                placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 40)
                },
                failure: {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
            )
            .frame(width: 40, height: 40)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(pos)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) {
                progress = 1.0
            }
            withAnimation(.easeIn(duration: 0.15).delay(0.40)) {
                scale = 0.4
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
                onComplete()
            }
        }
    }

    /// Computes a quadratic bezier arc between source and destination.
    private func currentPosition(progress: CGFloat) -> CGPoint {
        let dx = particle.destination.x - particle.source.x
        let dy = particle.destination.y - particle.source.y
        // Control point: slightly left and upward relative to the midpoint
        let control = CGPoint(
            x: particle.source.x + dx * 0.3 - 60,
            y: particle.source.y + dy * 0.3 - abs(dy) * 0.6 - 80
        )
        let t = progress
        let mt = 1 - t
        let x =
            mt * mt * particle.source.x + 2 * mt * t * control.x + t * t * particle.destination.x
        let y =
            mt * mt * particle.source.y + 2 * mt * t * control.y + t * t * particle.destination.y
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Recommended Product Card
struct RecommendedProductCard: View {
    let product: Product
    let onAdd: (CGRect) -> Void

    @State private var added = false
    @State private var buttonFrame: CGRect = .zero
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen cuadrada
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(
                    url: URL(string: product.imageUrl),
                    cacheKey: "product_\(product.id)",
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 148, height: 148)
                            .clipped()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 148, height: 148)
                    },
                    failure: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 148, height: 148)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(.systemGray3))
                            )
                    }
                )
                .frame(width: 148, height: 148)

                // Botón añadir (esquina inferior derecha sobre la imagen)
                Button(action: {
                    guard !added else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { added = true }
                    onAdd(buttonFrame)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { added = false }
                    }
                }) {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(added ? Color(.systemGreen) : Color(.label))
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        buttonFrame = geo.frame(in: .global)
                                    }
                            }
                        )
                }
                .buttonStyle(.plain)
                .padding(8)
                .scaleEffect(added ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: added)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 148)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Payment Link Sheet View
struct PaymentLinkSheetView: View {
    let paymentLink: String
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var showCopiedMessage = false

    private var copyButtonGradient: LinearGradient {
        let colors: [Color]
        if showCopiedMessage {
            colors = [gradientManager.currentAccentColor, gradientManager.currentAccentColor]
        } else {
            colors = [
                gradientManager.currentAccentColor,
                gradientManager.currentAccentColor,
            ]
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                HomeGradientBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            gradientManager.currentAccentColor.opacity(0.15),
                                            gradientManager.currentAccentColor.opacity(0.1),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            gradientManager.currentAccentColor,
                                            gradientManager.currentAccentColor,
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)

                        // Title & Description
                        VStack(spacing: 12) {
                            Text("Link de Pago Generado")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(
                                "Comparte este link con alguien en el exterior para que pague tu pedido"
                            )
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        }

                        // Link Container
                        VStack(spacing: 16) {
                            // Link Display
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text(paymentLink)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(.regularMaterial)
                            .cornerRadius(14)

                            // Copy Button
                            Button(action: {
                                UIPasteboard.general.string = paymentLink
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showCopiedMessage = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation {
                                        showCopiedMessage = false
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(
                                        systemName: showCopiedMessage
                                            ? "checkmark.circle.fill" : "doc.on.doc.fill"
                                    )
                                    .font(.system(size: 18, weight: .bold))

                                    Text(showCopiedMessage ? "¡Copiado!" : "Copiar Link")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(copyButtonGradient)
                                .cornerRadius(16)
                                .shadow(
                                    color: gradientManager.currentAccentColor.opacity(0.3),
                                    radius: 10,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .scaleEffect(showCopiedMessage ? 1.02 : 1.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7),
                                value: showCopiedMessage)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Instructions Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Instrucciones")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(number: "1", text: "Copia el link de pago")
                                InstructionRow(
                                    number: "2", text: "Envíalo por WhatsApp, email o mensaje")
                                InstructionRow(
                                    number: "3",
                                    text: "La persona paga de forma segura (Stripe próximamente)")
                                InstructionRow(
                                    number: "4",
                                    text: "Recibirás una notificación cuando se complete el pago")
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Factura al Exterior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                }
            }
        }
    }
}

// MARK: - Bank Transfer Sheet View
struct BankTransferSheetView: View {
    let totalAmount: String
    let allowAmountEditing: Bool
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var editableAmount: String
    @State private var transferId: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var validationState: ValidationState = .idle
    @State private var isValidating = false
    @State private var validationError: String = ""
    @State private var showValidationError = false
    @State private var lastValidationResult: PaymentValidationResult?

    private let cartRepository = CartRepository()

    enum ValidationState: Equatable {
        case idle
        case validating
        case validated
        case failed(String)
    }

    init(
        totalAmount: String,
        allowAmountEditing: Bool = false,
        onConfirm: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.totalAmount = totalAmount
        self.allowAmountEditing = allowAmountEditing
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _editableAmount = State(initialValue: totalAmount)
    }

    // Datos bancarios de ejemplo
    let bankAccountNumber = "9225 8899 0012 3456"
    let phoneNumber = "+53 5234 5678"
    let bankName = "Banco Metropolitano"

    private var currentAmountText: String {
        let value = allowAmountEditing ? editableAmount : totalAmount
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAmountProvided: Bool {
        !currentAmountText.isEmpty
    }

    @ViewBuilder
    private func validationOverlay() -> some View {
        switch validationState {
        case .validating:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    VStack(spacing: 16) {
                        LottieView(name: "loading")
                            .frame(width: 80, height: 80)
                        Text("Verificando comprobante...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                )
        case .validated:
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentAccentColor)
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(
                        color: gradientManager.currentAccentColor.opacity(0.5), radius: 8, x: 0,
                        y: 4
                    )
                    .padding()
                }
                Spacer()
            }
        case .failed:
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 40, height: 40)
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.red.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding()
                }
                Spacer()
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.llegoBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        titleSection

                        // Bank Information Card
                        VStack(spacing: 16) {
                            // Bank Name
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Banco")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(bankName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()
                            }

                            Divider()

                            // Card Number
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Número de Tarjeta")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(bankAccountNumber)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = bankAccountNumber
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                        .padding(8)
                                        .background(
                                            Circle().fill(
                                                gradientManager.currentAccentColor.opacity(0.15)))
                                }
                            }

                            Divider()

                            // Phone Number
                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Teléfono de Confirmación")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(phoneNumber)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()
                            }

                            Divider()

                            // Amount
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monto a Transferir")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    if allowAmountEditing {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            TextField("0.00", text: $editableAmount)
                                                .font(
                                                    .system(
                                                        size: 20, weight: .bold, design: .rounded)
                                                )
                                                .keyboardType(.decimalPad)
                                                .foregroundColor(gradientManager.currentAccentColor)
                                                .multilineTextAlignment(.leading)

                                            Text("CUP")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(
                                                    gradientManager.currentAccentColor.opacity(0.85)
                                                )
                                        }
                                    } else {
                                        Text(totalAmount)
                                            .font(
                                                .system(size: 20, weight: .bold, design: .rounded)
                                            )
                                            .foregroundColor(gradientManager.currentAccentColor)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)

                        // Transfer ID Input Section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Identificador de Transferencia")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Spacer()
                            }

                            TextField("Ej: 1234567890", text: $transferId)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    transferId.isEmpty
                                                        ? Color.gray.opacity(0.3)
                                                        : gradientManager.currentAccentColor,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .autocapitalization(.none)
                                .keyboardType(.numberPad)
                        }
                        .padding(.horizontal, 20)

                        // Upload Receipt Section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "photo.badge.plus.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Comprobante de Pago")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Spacer()

                                if validationState == .validated {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Verificado")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(gradientManager.currentAccentColor.opacity(0.15))
                                    )
                                }
                            }

                            if let image = selectedImage {
                                // Image Preview with Validation State
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))

                                    // Validation Overlay
                                    validationOverlay()
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            strokeColorForValidationState(),
                                            lineWidth: 2
                                        )
                                )

                                // Change Image Button
                                if case .validating = validationState {
                                    EmptyView()
                                } else {
                                    Button(action: {
                                        // Reset validation state
                                        validationState = .idle
                                        lastValidationResult = nil
                                        showImagePicker = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Cambiar imagen")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(gradientManager.currentAccentColor)
                                        .padding(.vertical, 8)
                                    }
                                }

                                if let validationResult = lastValidationResult {
                                    validationResultSummary(result: validationResult)
                                        .padding(.top, 12)
                                }
                            } else {
                                // Upload Button
                                Button(action: {
                                    if !transferId.isEmpty {
                                        showImagePicker = true
                                    }
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.llegoSecondary.opacity(0.15))
                                                .frame(width: 60, height: 60)

                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 28, weight: .medium))
                                                .foregroundColor(.llegoSecondary)
                                        }

                                        Text("Subir Comprobante")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(
                                                transferId.isEmpty ? .gray : gradientManager.currentAccentColor)

                                        Text(
                                            transferId.isEmpty
                                                ? "Primero introduce el identificador"
                                                : "Toca para seleccionar una imagen"
                                        )
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                            )
                                            .foregroundColor(Color.llegoSecondary.opacity(0.3))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Confirm Button
                        Button(action: {
                            onConfirm(currentAmountText)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))

                                Text("Confirmar Transferencia")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        gradientManager.currentAccentColor,
                                        gradientManager.currentAccentColor,
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: validationState == .validated
                                    ? gradientManager.currentAccentColor.opacity(0.4)
                                    : Color.gray.opacity(0.2),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(validationState != .validated || !isAmountProvided)
                        .opacity(validationState == .validated && isAmountProvided ? 1.0 : 0.4)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Transferencia Bancaria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    image: $selectedImage,
                    onImageSelected: {
                        // Iniciar validación con el servicio REST de pagos
                        validateReceipt()
                    })
            }
            .alert("Error de Validación", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {
                    showValidationError = false
                }
            } message: {
                Text(validationError)
            }
        }
    }

    private var headerSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoSecondary.opacity(0.2),
                            Color.llegoSecondary.opacity(0.1),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: "building.columns.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(Color.llegoSecondary)
        }
        .padding(.top, 20)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Transferencia Bancaria")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(gradientManager.currentAccentColor)

            Text("Realiza tu transferencia y sube el comprobante")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func strokeColorForValidationState() -> Color {
        switch validationState {
        case .validated:
            return gradientManager.currentAccentColor
        case .failed:
            return Color.red
        default:
            return Color.gray.opacity(0.3)
        }
    }

    private func validationResultSummary(result: PaymentValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(
                    systemName: result.matched
                        ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                )
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(result.matched ? gradientManager.currentAccentColor : .red)

                Text(result.matched ? "Transferencia validada" : "Verifica el identificador")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(result.matched ? gradientManager.currentAccentColor : .red)

                Spacer()
            }

            if let detected = result.detectedTransferId, !detected.isEmpty {
                validationDetailRow(title: "ID detectado", value: detected)
            }

            if let data = result.extractedData {
                if let banco = data.banco, !banco.isEmpty {
                    validationDetailRow(title: "Banco", value: banco)
                }
                if let quienEnvio = data.quienEnvio, !quienEnvio.isEmpty {
                    validationDetailRow(title: "Quién envió", value: quienEnvio)
                }
                if let fecha = data.fecha, !fecha.isEmpty {
                    validationDetailRow(title: "Fecha", value: fecha)
                }
                if let monto = data.cantidadTransferida {
                    validationDetailRow(
                        title: "Monto detectado", value: String(format: "%.2f CUP", monto))
                }
                if let numero = data.numeroTransferencia, !numero.isEmpty {
                    validationDetailRow(title: "Número en comprobante", value: numero)
                }
            }

            if let savedId = result.savedPayment?.id, !savedId.isEmpty {
                validationDetailRow(title: "Registro guardado", value: savedId)
            }

            Text(result.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    result.matched
                        ? gradientManager.currentAccentColor.opacity(0.4) : Color.red.opacity(0.4),
                    lineWidth: 1.5
                )
        )
    }

    private func validationDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(gradientManager.currentAccentColor)
        }
    }

    private func validateReceipt() {
        guard let image = selectedImage else { return }
        guard !transferId.isEmpty else {
            validationError = "Debes introducir el identificador de transferencia primero"
            showValidationError = true
            return
        }

        validationState = .validating
        lastValidationResult = nil

        // Llamar al repository para validar la imagen
        cartRepository.validatePaymentImage(image: image, transferId: transferId) { result in
            switch result {
            case .success(let paymentResult):
                lastValidationResult = paymentResult

                if let isBankMessage = paymentResult.extractedData?.esMensajeBanco,
                    isBankMessage == false
                {
                    let errorMsg = "La imagen no parece ser un mensaje de banco válido."
                    validationState = .failed(errorMsg)
                    validationError = errorMsg
                    showValidationError = true
                    print("❌ Validación fallida: \(errorMsg)")
                    return
                }

                guard paymentResult.matched else {
                    let detected =
                        paymentResult.detectedTransferId ?? paymentResult.extractedData?
                        .numeroTransferencia ?? "no detectado"
                    let errorMsg = """
                        El identificador no coincide.
                        Ingresado: \(transferId)
                        Detectado: \(detected)
                        \(paymentResult.message)
                        """
                    validationState = .failed(errorMsg)
                    validationError = errorMsg
                    showValidationError = true
                    print("❌ Validación fallida: \(errorMsg)")
                    return
                }

                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    validationState = .validated
                }
                showValidationError = false
                validationError = ""

                print("✅ Validación exitosa!")
                print("   Message: \(paymentResult.message)")
                print("   Detectado: \(paymentResult.detectedTransferId ?? "n/a")")
                if let banco = paymentResult.extractedData?.banco {
                    print("   Banco: \(banco)")
                }
                if let monto = paymentResult.extractedData?.cantidadTransferida {
                    print("   Monto: \(monto)")
                }

            case .failure(let error):
                lastValidationResult = nil
                let errorMsg = "Error al validar: \(error.localizedDescription)"
                validationState = .failed(errorMsg)
                validationError = errorMsg
                showValidationError = true
                print("❌ Error de validación: \(errorMsg)")
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: () -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Ad Watcher View (Mandatory Ads for Discount)
struct AdWatcherView: View {
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentAdIndex: Int = 0
    @State private var secondsRemaining: Int = 30
    @State private var canSkip: Bool = true  // TODO: Cambiar a false para producción
    @State private var isVideoPlaying: Bool = true
    @State private var showCompletionAnimation: Bool = false
    @State private var timer: Timer?

    private let totalAds = 2
    private let skipAfterSeconds = 30

    // Simulated ad data
    private let ads: [(title: String, brand: String, color: Color, icon: String)] = [
        ("Descubre ofertas increíbles", "MegaStore", .blue, "bag.fill"),
        ("Tu próximo viaje te espera", "TravelMax", .purple, "airplane"),
    ]

    var body: some View {
        ZStack {
            // Background gradient based on current ad
            LinearGradient(
                colors: [
                    ads[currentAdIndex].color.opacity(0.8),
                    ads[currentAdIndex].color.opacity(0.4),
                    Color.black.opacity(0.9),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with progress and timer
                adTopBar

                Spacer()

                // Simulated video content
                simulatedVideoContent

                Spacer()

                // Bottom controls
                adBottomControls
            }

            // Completion animation overlay
            if showCompletionAnimation {
                completionOverlay
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Top Bar
    private var adTopBar: some View {
        VStack(spacing: 12) {
            // Progress indicators
            HStack(spacing: 6) {
                ForEach(0..<totalAds, id: \.self) { index in
                    Capsule()
                        .fill(
                            index < currentAdIndex
                                ? Color.white
                                : (index == currentAdIndex
                                    ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                        )
                        .frame(height: 3)
                        .overlay(
                            GeometryReader { geo in
                                if index == currentAdIndex {
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(
                                            width: geo.size.width
                                                * CGFloat(skipAfterSeconds - secondsRemaining)
                                                / CGFloat(skipAfterSeconds))
                                }
                            }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Ad info and timer
            HStack {
                // Ad counter
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Anuncio \(currentAdIndex + 1) de \(totalAds)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Timer badge
                HStack(spacing: 4) {
                    Image(systemName: canSkip ? "forward.fill" : "clock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(canSkip ? "Omitir" : "\(secondsRemaining)s")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(canSkip ? Color.green : Color.white.opacity(0.2))
                )
                .onTapGesture {
                    if canSkip {
                        skipOrFinishAd()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 50)
    }

    // MARK: - Simulated Video Content
    private var simulatedVideoContent: some View {
        VStack(spacing: 24) {
            // Brand icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: ads[currentAdIndex].icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isVideoPlaying ? 1.0 : 0.95)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isVideoPlaying)

            // Ad text
            VStack(spacing: 12) {
                Text(ads[currentAdIndex].brand)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)

                Text(ads[currentAdIndex].title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Simulated video progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(skipAfterSeconds - secondsRemaining)
                                    / CGFloat(skipAfterSeconds), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)

                // Video duration indicator
                HStack {
                    Text(formatTime(skipAfterSeconds - secondsRemaining))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(formatTime(skipAfterSeconds))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Bottom Controls
    private var adBottomControls: some View {
        VStack(spacing: 16) {
            // Info about discount
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))

                Text("Mira \(totalAds) videos y reduce tu cargo de servicio al 10%")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )

            // Sound toggle (simulated)
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.bottom, 50)
    }

    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(spacing: 8) {
                    Text("¡Descuento activado!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Tu cargo de servicio ahora es del 10%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Button(action: {
                    onComplete()
                }) {
                    Text("Continuar")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .modifier(GlassProminentButtonModifier())
                .tint(.green)
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Timer Logic
    private func startTimer() {
        secondsRemaining = skipAfterSeconds
        canSkip = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
                if secondsRemaining == 0 {
                    canSkip = true
                }
            }
        }
    }

    private func skipOrFinishAd() {
        timer?.invalidate()

        if currentAdIndex < totalAds - 1 {
            // Move to next ad
            withAnimation(.easeInOut(duration: 0.3)) {
                currentAdIndex += 1
            }
            startTimer()
        } else {
            // All ads watched - show completion
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCompletionAnimation = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
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
