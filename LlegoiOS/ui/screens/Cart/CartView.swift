import SwiftUI
import StripePaymentSheet
import LocalAuthentication
import AudioToolbox

enum Currency: String, CaseIterable {
    case CUP = "CUP"
    case USD = "USD"
    case EUR = "EUR"
    case MXN = "MXN"

    var flag: String {
        switch self {
        case .CUP: return "🇨🇺"
        case .USD: return "🇺🇸"
        case .EUR: return "🇪🇺"
        case .MXN: return "🇲🇽"
        }
    }

    var symbol: String {
        switch self {
        case .CUP: return "CUP"
        case .USD: return "$"
        case .EUR: return "€"
        case .MXN: return "MX$"
        }
    }
}

struct CartView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CartViewModel()
    @State private var selectedCurrency: Currency = .CUP
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showPaymentMethodPicker = false
    @State private var navigateToPlans = false

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
    private let paymentRepository = PaymentRepository()

    let paymentMethods: [PaymentMethod] = [
        PaymentMethod(
            id: "invoice_international",
            name: "ENviar factura a persona en el extranjero",
            description: "Enviar link de pago",
            imageType: .systemIcon("link.circle.fill"),
            color: Color(red: 0.2, green: 0.5, blue: 0.9),
            currency: "USD"
        ),
        PaymentMethod(
            id: "cash_cup",
            name: "Efectivo",
            description: "Pago al recibir",
            imageType: .systemIcon("banknote"),
            color: Color.llegoPrimary,
            currency: "CUP"
        ),
        PaymentMethod(
            id: "cash_usd",
            name: "Efectivo",
            description: "Pago al recibir",
            imageType: .systemIcon("dollarsign.circle"),
            color: Color.llegoAccent,
            currency: "USD"
        ),
        PaymentMethod(
            id: "bank_transfer",
            name: "Transferencia",
            description: "Transferencia bancaria",
            imageType: .systemIcon("building.columns"),
            color: Color.llegoSecondary,
            currency: "CUP"
        ),
        PaymentMethod(
            id: "credit_card",
            name: "Tarjeta",
            description: "Visa/Mastercard",
            imageType: .systemIcon("creditcard"),
            color: Color.llegoTertiary,
            currency: "USD"
        ),
        PaymentMethod(
            id: "qvapay",
            name: "QvaPay",
            description: "Pago digital",
            imageType: .assetImage("qvapay"),
            color: Color(red: 0.2, green: 0.6, blue: 0.9),
            currency: "CUP/USD"
        ),
        PaymentMethod(
            id: "tropipay",
            name: "TropiPay",
            description: "Cartera digital",
            imageType: .assetImage("tropipay"),
            color: Color(red: 0.9, green: 0.4, blue: 0.1),
            currency: "CUP/USD"
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background moderno consistente con WelcomeView, ShopView, ConversationalSearchView
                WelcomeGradientBackground()
                    .ignoresSafeArea()

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
                        .background(Color.llegoAccent)
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
                            ForEach(Array(viewModel.cartItems.enumerated()), id: \.element.id) { index, item in
                                CartItemCard(
                                    item: item,
                                    onIncrement: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            viewModel.incrementQuantity(productId: item.id)
                                        }
                                    },
                                    onDecrement: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            viewModel.decrementQuantity(productId: item.id)
                                        }
                                    },
                                    onRemove: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            viewModel.removeFromCart(productId: item.id)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: viewModel.cartItems.count)
                            }

                            // Resumen de precios
                            priceBreakdown
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 0) {
                            // Línea divisoria sutil
                            Divider()
                                .background(Color.gray.opacity(0.2))
                            
                            VStack(spacing: 12) {
                                // Seguridad badge
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.llegoAccent)
                                    
                                    Text("Pago seguro y protegido")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                .padding(.top, 8)
                                
                                // Botones de acción
                                HStack(spacing: 10) {
                                    Button(action: {
                                        showPaymentMethodPicker = true
                                    }) {
                                        HStack(spacing: 6) {
                                            if let method = selectedPaymentMethod {
                                                switch method.imageType {
                                                case .systemIcon(let iconName):
                                                    Image(systemName: iconName)
                                                        .font(.system(size: 14, weight: .semibold))
                                                case .assetImage(let imageName):
                                                    Image(imageName)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text("Pagar con")
                                                        .font(.system(size: 11, weight: .medium))
                                                    Text(method.name)
                                                        .font(.system(size: 13, weight: .bold))
                                                }
                                            } else {
                                                Image(systemName: "creditcard")
                                                    .font(.system(size: 14, weight: .semibold))
                                                Text("Método")
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                    }
                                    .buttonStyle(.glass)
                                    
                                    Button(action: {
                                        processPayment()
                                    }) {
                                        HStack(spacing: 6) {
                                            if selectedPaymentMethod?.id == "invoice_international" {
                                                Text("Enviar factura")
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                            } else {
                                                Text("Pagar")
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                Text(viewModel.formattedTotal)
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                    }
                                    .buttonStyle(.glassProminent)
                                    .tint(.llegoPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                            .background(.ultraThinMaterial)
                        }
                    }

                    NavigationLink(
                        destination: PlansAndPricingView(),
                        isActive: $navigateToPlans
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
            .navigationTitle("Carrito")
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedCurrency = currency
                                }
                            }) {
                                HStack {
                                    Text(currency.flag)
                                        .font(.system(size: 20))
                                    Text(currency.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedCurrency == currency {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.llegoAccent)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedCurrency.flag)
                                .font(.system(size: 18))
                            Text(selectedCurrency.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.llegoPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.llegoPrimary)
                        }
                        .frame(width: 85, height: 40)
                    }
                }
            }
            .sheet(isPresented: $showPaymentMethodPicker) {
                PaymentMethodPickerView(
                    paymentMethods: paymentMethods,
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
                        // Mostrar pantalla de confirmación (FullScreenCover)
                        // Limpiar carrito después un momento o dejar que la confirmación lo maneje si fuera necesario,
                        // pero aquí limpiamos los datos del ViewModel.
                        viewModel.clearCart()
                        
                        // Pequeño delay para una transición suave
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showOrderConfirmation = true
                        }
                    },
                    onDismiss: {
                        showBankTransferSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .alert("Estado del Pago", isPresented: $showPaymentAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(paymentAlertMessage)
            }
            .overlay {
                if isLoadingPayment {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            LottieView(name: "loading")
                                .frame(width: 150, height: 150)
                            Text("Preparando pago...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.llegoBackground)
                        )
                    }
                }
            }
            .onAppear {
                viewModel.loadCart()
            }
            .fullScreenCover(isPresented: $showOrderConfirmation) {
                OrderConfirmationView(
                    deliveryLocation: "Calle 23 #456, Vedado, La Habana", //TODO: Usar ubicación real del usuario
                    selectedPaymentMethod: selectedPaymentMethod?.name ?? "Método de Pago"
                )
            }
        }
        
        
    }

    // MARK: - Payment Method Selector
    private var paymentMethodSelector: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Método de Pago")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

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
                    .foregroundColor(.llegoAccent)
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
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(method.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

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
            let reason = "Confirma tu identidad para realizar el pago de \(viewModel.formattedTotal)"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
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
        // Si el método de pago es factura internacional, generar payment link
        if paymentMethod.id == "invoice_international" {
            generatePaymentLink()
        }
        // Si el método de pago es transferencia bancaria, mostrar sheet
        else if paymentMethod.id == "bank_transfer" {
            showBankTransferSheet = true
        }
        // Si el método de pago es tarjeta de crédito, usar Stripe
        else if paymentMethod.id == "credit_card" {
            initiateStripePayment()
        } else {
            // Para otros métodos de pago (Efectivo, QvaPay, etc.) simular proceso
            isLoadingPayment = true
            
            // Simular delay de red
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoadingPayment = false
                
                // Limpiar carrito
                viewModel.clearCart()
                
                // Mostrar confirmación
                showOrderConfirmation = true
            }
        }
    }

    // MARK: - Generate Payment Link
    private func generatePaymentLink() {
        isLoadingPayment = true

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
    }

    // MARK: - Stripe Payment
    private func initiateStripePayment() {
        isLoadingPayment = true

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
        appearance.colors.primary = UIColor(Color.llegoPrimary)
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
              let rootViewController = windowScene.windows.first?.rootViewController else {
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
            
            // Limpiar carrito
            viewModel.clearCart()
            
            // Mostrar Confirmación
            showOrderConfirmation = true

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

    

    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icono grande con gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary.opacity(0.1),
                                Color.llegoAccent.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "cart")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary.opacity(0.7),
                                Color.llegoAccent.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("Tu carrito está vacío")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Agrega productos para comenzar tu pedido")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
               dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))

                    Text("Explorar Productos")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 250, height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.llegoAccent, Color.llegoPrimary]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 16)

            Spacer()
        }
    }

    private var priceBreakdown: some View {
        VStack(spacing: 14) {
            // Subtotal
            HStack {
                Text("Subtotal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text(viewModel.formattedSubtotal)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Envío
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.llegoAccent)

                    Text("Envío")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(viewModel.formattedDeliveryFee)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }

            shippingTipCard

            Divider()
                .background(Color.gray.opacity(0.2))
                .padding(.vertical, 4)

            // Total
            HStack {
                Text("Total")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text(viewModel.formattedTotal)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var tipAttributedString: AttributedString {
        var base = AttributedString("Recomendamos elegir productos de un mismo vendedor para hacer más barato el envío o ")
        base.font = .system(size: 13, weight: .medium)
        base.foregroundColor = .gray

        var action = AttributedString("suscribirse")
        action.font = .system(size: 13, weight: .semibold)
        action.foregroundColor = .llegoAccent
        action.underlineStyle = .single

        return base + action
    }

    private var shippingTipCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.llegoAccent)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tip")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Button(action: {
                    navigateToPlans = true
                }) {
                    Text(tipAttributedString)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
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
                // Fondo moderno
                WelcomeGradientBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header minimalista
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard.circle.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoAccent,
                                            Color.llegoPrimary
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Selecciona tu método de pago")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Elige cómo quieres pagar tu pedido")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        // Lista de métodos de pago
                        LazyVStack(spacing: 12) {
                            ForEach(paymentMethods, id: \.id) { method in
                                PaymentMethodRow(
                                    method: method,
                                    isSelected: selectedMethod?.id == method.id
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedMethod = method
                                    }
                                    // Cerrar después de seleccionar
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
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
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icono del método
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(method.color.opacity(0.12))
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
                            .frame(width: 28, height: 28)
                    }
                }

                // Información del método
                VStack(alignment: .leading, spacing: 5) {
                    Text(method.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(method.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    // Moneda
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.system(size: 10, weight: .medium))
                        Text(method.currency)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(method.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(method.color.opacity(0.10))
                    .cornerRadius(6)
                }

                Spacer()

                // Indicador de selección
                ZStack {
                    Circle()
                        .stroke(isSelected ? method.color : Color.secondary.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(method.color)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? method.color.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 8,
                        x: 0, y: 2
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CartItemCard: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Imagen del producto
            CachedAsyncImage(
                url: URL(string: item.imageUrl),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    ProgressView()
                }
            )
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.thinMaterial)
            )

            // Información del producto
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.shop)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(item.weight)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.llegoAccent)
                }

                // Precio y total
                HStack(spacing: 6) {
                    Text(item.formattedPrice)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("× \(item.quantity)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.llegoPrimary)

                    Text("=")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(item.formattedItemTotal)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Payment Link Sheet View
struct PaymentLinkSheetView: View {
    let paymentLink: String
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedMessage = false

    private var copyButtonGradient: LinearGradient {
        let colors: [Color]
        if showCopiedMessage {
            colors = [Color.llegoAccent, Color.llegoAccent]
        } else {
            colors = [
                Color.llegoPrimary,
                Color.llegoAccent
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
                WelcomeGradientBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary.opacity(0.15),
                                            Color.llegoAccent.opacity(0.1)
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
                                            Color.llegoPrimary,
                                            Color.llegoAccent
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

                            Text("Comparte este link con alguien en el exterior para que pague tu pedido")
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
                                    .foregroundColor(.llegoPrimary)

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
                                    Image(systemName: showCopiedMessage ? "checkmark.circle.fill" : "doc.on.doc.fill")
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
                                    color: Color.llegoPrimary.opacity(0.3),
                                    radius: 10,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .scaleEffect(showCopiedMessage ? 1.02 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showCopiedMessage)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Instructions Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.llegoPrimary)

                                Text("Instrucciones")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(number: "1", text: "Copia el link de pago")
                                InstructionRow(number: "2", text: "Envíalo por WhatsApp, email o mensaje")
                                InstructionRow(number: "3", text: "La persona paga de forma segura con Stripe")
                                InstructionRow(number: "4", text: "Recibirás una notificación cuando se complete el pago")
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
                    .foregroundColor(.llegoPrimary)
                }
            }
        }
    }
}

// MARK: - Instruction Row Helper
struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.12))
                    .frame(width: 26, height: 26)

                Text(number)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
                            .fill(Color.llegoAccent)
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.llegoAccent.opacity(0.5), radius: 8, x: 0, y: 4)
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
                                        .foregroundColor(.llegoPrimary)
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
                                        .foregroundColor(.llegoPrimary)
                                }

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = bankAccountNumber
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.llegoAccent)
                                        .padding(8)
                                        .background(Circle().fill(Color.llegoAccent.opacity(0.15)))
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
                                        .foregroundColor(.llegoPrimary)
                                }

                                Spacer()
                            }

                            Divider()

                            // Amount
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoAccent)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monto a Transferir")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    if allowAmountEditing {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            TextField("0.00", text: $editableAmount)
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .keyboardType(.decimalPad)
                                                .foregroundColor(.llegoAccent)
                                                .multilineTextAlignment(.leading)

                                            Text("CUP")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.llegoAccent.opacity(0.85))
                                        }
                                    } else {
                                        Text(totalAmount)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.llegoAccent)
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
                                    .foregroundColor(.llegoPrimary)

                                Text("Identificador de Transferencia")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.llegoPrimary)

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
                                                    transferId.isEmpty ? Color.gray.opacity(0.3) : Color.llegoAccent,
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
                                    .foregroundColor(.llegoPrimary)

                                Text("Comprobante de Pago")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.llegoPrimary)

                                Spacer()

                                if validationState == .validated {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Verificado")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.llegoAccent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.llegoAccent.opacity(0.15))
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
                                        .foregroundColor(.llegoPrimary)
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
                                            .foregroundColor(transferId.isEmpty ? .gray : .llegoPrimary)

                                        Text(transferId.isEmpty ? "Primero introduce el identificador" : "Toca para seleccionar una imagen")
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
                                        Color.llegoAccent,
                                        Color.llegoPrimary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: validationState == .validated ? Color.llegoAccent.opacity(0.4) : Color.gray.opacity(0.2),
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
                ImagePicker(image: $selectedImage, onImageSelected: {
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
                            Color.llegoSecondary.opacity(0.1)
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
                .foregroundColor(.llegoPrimary)

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
            return Color.llegoAccent
        case .failed:
            return Color.red
        default:
            return Color.gray.opacity(0.3)
        }
    }

    private func validationResultSummary(result: PaymentValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: result.matched ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(result.matched ? .llegoAccent : .red)

                Text(result.matched ? "Transferencia validada" : "Verifica el identificador")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(result.matched ? .llegoAccent : .red)

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
                    validationDetailRow(title: "Monto detectado", value: String(format: "%.2f CUP", monto))
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
                    result.matched ? Color.llegoAccent.opacity(0.4) : Color.red.opacity(0.4),
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
                .foregroundColor(.llegoPrimary)
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

                if let isBankMessage = paymentResult.extractedData?.esMensajeBanco, isBankMessage == false {
                    let errorMsg = "La imagen no parece ser un mensaje de banco válido."
                    validationState = .failed(errorMsg)
                    validationError = errorMsg
                    showValidationError = true
                    print("❌ Validación fallida: \(errorMsg)")
                    return
                }

                guard paymentResult.matched else {
                    let detected = paymentResult.detectedTransferId ?? paymentResult.extractedData?.numeroTransferencia ?? "no detectado"
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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

#Preview {
    CartView()
}
