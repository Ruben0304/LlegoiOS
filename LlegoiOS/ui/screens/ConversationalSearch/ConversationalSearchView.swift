//
//  ConversationalSearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda conversacional premium
//  Inspirada en Gleb Kuznetsov y Apple Design Awards
//

import SwiftUI

enum ConversationalSearchState {
    case idle
    case streaming
    case waitingInput
    case searching
    case completed
}

enum ConversationStep {
    case selectingProductAndStore
    case selectingPayment
    case showingConfirmation
}

struct ConversationalSearchView: View {
    @Environment(\.dismiss) private var dismiss

    // Initial step configuration
    let initialStep: ConversationStep
    let onComplete: () -> Void

    // Conversation flow
    @State private var currentStep: ConversationStep
    @State private var state: ConversationalSearchState = .idle
    
    // Track if we're showing confirmation after third video
    @State private var isFinalConfirmation: Bool = false

    // User selections
    @State private var firstProductValue: String? = nil
    @State private var secondProductValue: String? = nil
    @State private var storeValue: String? = nil
    @State private var currencyValue: String? = nil
    @State private var paymentMethodValue: String? = nil

    // UI expansion states
    @State private var firstProductExpanded: Bool = false
    @State private var secondProductExpanded: Bool = false
    @State private var storeExpanded: Bool = false
    @State private var currencyExpanded: Bool = false
    @State private var paymentMethodExpanded: Bool = false

    // Streaming animation (solo para cliente)
    @State private var showAvatar: Bool = false
    @State private var showBubble: Bool = false
    @State private var startStreaming: Bool = false

    // Confirmation button
    @State private var showConfirmButton: Bool = false
    
    // Navigation state
    @State private var navigateToIntroVideo: Bool = false
    
    init(initialStep: ConversationStep = .selectingProductAndStore, onComplete: @escaping () -> Void = {}) {
        self.initialStep = initialStep
        self.onComplete = onComplete
        _currentStep = State(initialValue: initialStep)
    }

    var body: some View {
        ZStack {
            // Mismo fondo que WelcomeView
            WelcomeGradientBackground()
                .ignoresSafeArea()

            // Contenido principal centrado
            VStack {
                Spacer()
                    .frame(height: 100) // Offset hacia arriba desde el centro

                // Avatar y burbuja de conversación del cliente
                chatBubbleView
                    .transition(.opacity)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Overlay oscuro cuando algún picker está expandido
            if firstProductExpanded || secondProductExpanded || storeExpanded ||
               currencyExpanded || paymentMethodExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            closeAllPickers()
                        }
                    }
            }

            // Cards y pickers flotantes
            VStack {
                Spacer()
                    .frame(height: 80)

                // Picker del primer producto
                if firstProductExpanded {
                    FloatingSearchCard(
                        type: .products,
                        selectedValue: $firstProductValue,
                        isVisible: $firstProductExpanded
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                // Picker del segundo producto (con opción "más nada")
                if secondProductExpanded {
                    FloatingSearchCard(
                        type: .products,
                        selectedValue: $secondProductValue,
                        isVisible: $secondProductExpanded,
                        showNothingElseOption: true
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                // Picker del vendedor
                if storeExpanded {
                    FloatingSearchCard(
                        type: .stores,
                        selectedValue: $storeValue,
                        isVisible: $storeExpanded
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                // Picker de moneda
                if currencyExpanded {
                    FloatingSimpleListPicker(
                        title: "Selecciona la moneda",
                        items: [
                            SimpleCurrency(id: "CUP", name: "CUP", flag: "🇨🇺"),
                            SimpleCurrency(id: "USD", name: "USD", flag: "🇺🇸")
                        ],
                        itemLabel: { $0.name },
                        itemIcon: { currency in
                            AnyView(
                                Text(currency.flag)
                                    .font(.system(size: 32))
                            )
                        },
                        selectedValue: $currencyValue,
                        isVisible: $currencyExpanded
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                // Picker de método de pago
                if paymentMethodExpanded {
                    FloatingSimpleListPicker(
                        title: "Selecciona método de pago",
                        items: paymentMethods,
                        itemLabel: { $0.name },
                        itemIcon: { method in
                            AnyView(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(method.color.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    switch method.imageType {
                                    case .systemIcon(let iconName):
                                        Image(systemName: iconName)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(method.color)
                                    case .assetImage(let imageName):
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                    }
                                }
                            )
                        },
                        selectedValue: $paymentMethodValue,
                        isVisible: $paymentMethodExpanded
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Botón de confirmación (aparece al final)
            if showConfirmButton {
                VStack {
                    Spacer()

                    Button(action: {
                        confirmOrder()
                    }) {
                        Text("Confirmar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.llegoPrimary)
                            )
                            .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .navigationDestination(isPresented: $navigateToIntroVideo) {
            EmptyView()
        }
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Chat Bubble View
    private var chatBubbleView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Avatar (cambia según el paso - no mostrar si es confirmación final)
            if showAvatar && !(isFinalConfirmation && currentStep == .showingConfirmation) {
                avatarView
                    .padding(.leading, 32)
                    .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                    .transition(
                        .scale(scale: 0.85)
                        .combined(with: .opacity)
                    )
            }

            // Texto conversacional dinámico
            if showBubble {
                VStack(alignment: .leading, spacing: 16) {
                    if startStreaming {
                        conversationContent
                    }
                }
                .padding(.horizontal, 32)
                .transition(
                    .scale(scale: 0.98)
                    .combined(with: .opacity)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: firstProductValue) { _ in handleFirstProductSelection() }
        .onChange(of: secondProductValue) { _ in handleSecondProductSelection() }
        .onChange(of: storeValue) { _ in handleStoreSelection() }
        .onChange(of: currencyValue) { _ in handleCurrencySelection() }
        .onChange(of: paymentMethodValue) { _ in handlePaymentMethodSelection() }
    }

    // Avatar del cliente (siempre el mismo)
    private var avatarView: some View {
        AsyncImage(url: URL(string: "https://i.pravatar.cc/100?img=3")) { phase in
            ZStack {
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color.llegoAccent.opacity(0.45))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.95))
                        )
                default:
                    Circle()
                        .fill(Color.llegoAccent.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.85)))
                        )
                }
            }
            .frame(width: 48, height: 48)
        }
    }

    // Contenido dinámico según el paso de la conversación
    @ViewBuilder
    private var conversationContent: some View {
        switch currentStep {
        case .selectingProductAndStore:
            // Cliente: "Quiero ordenar [producto] del vendedor [store]"
            // AMBOS selectores aparecen juntos desde el inicio
            StreamingTextView(
                segments: productAndStoreSegments,
                font: .system(size: 28, weight: .medium),
                color: Color.primary.opacity(0.75),
                wordDelay: 0.2,
                onComplete: {
                    state = .waitingInput
                }
            )
            .id("products_store_\(firstProductValue ?? "")_\(secondProductValue ?? "")_\(storeValue ?? "")")

        case .selectingPayment:
            // El usuario responde: "Usaré la moneda [escoger] usando la vía [escoger]"
            // AMBOS selectores aparecen juntos desde el inicio
            StreamingTextView(
                segments: paymentSegments,
                font: .system(size: 28, weight: .medium),
                color: Color.primary.opacity(0.75),
                wordDelay: 0.15,
                onComplete: {
                    state = .waitingInput
                }
            )
            .id("payment_\(currencyValue ?? "")_\(paymentMethodValue ?? "")")

        case .showingConfirmation:
            // "Vale, el costo total del envío es X en [moneda] y el envío es X, ¿quieres confirmar?"
            StreamingTextView(
                segments: [
                    .text(confirmationText)
                ],
                font: .system(size: 28, weight: .medium),
                color: Color.primary.opacity(0.75),
                wordDelay: 0.15,
                onComplete: {
                    // Mostrar botón de confirmación con fade
                    withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                        showConfirmButton = true
                    }
                }
            )
            .id("confirmation_\(currentStep)")
        }
    }

    // Segmentos para producto y vendedor (AMBOS aparecen juntos)
    private var productAndStoreSegments: [TextSegment] {
        var segments: [TextSegment] = [
            .text("Quiero ordenar"),
            .component(id: "first_product", AnyView(
                InlineSelectField(
                    type: .products,
                    selectedValue: $firstProductValue,
                    isExpanded: $firstProductExpanded
                )
            ))
        ]

        // Si ya se seleccionó el primer producto, mostrar "y" y segundo selector
        if firstProductValue != nil {
            segments.append(.text(" y"))
            segments.append(.component(id: "second_product", AnyView(
                InlineSelectField(
                    type: .products,
                    selectedValue: $secondProductValue,
                    isExpanded: $secondProductExpanded
                )
            )))
        }

        // SIEMPRE mostrar el selector de vendedor desde el inicio
        segments.append(.text(" del vendedor"))
        segments.append(.component(id: "store", AnyView(
            InlineSelectField(
                type: .stores,
                selectedValue: $storeValue,
                isExpanded: $storeExpanded
            )
        )))

        return segments
    }

    // Segmentos para método de pago (AMBOS selectores aparecen juntos)
    private var paymentSegments: [TextSegment] {
        // SIEMPRE mostrar AMBOS selectores desde el inicio
        [
            .text("Usaré la moneda"),
            .component(id: "currency", AnyView(
                InlineSelectField(
                    type: .products, // Reutilizamos el tipo pero lo usaremos para moneda
                    selectedValue: $currencyValue,
                    isExpanded: $currencyExpanded
                )
            )),
            .text(" usando la vía"),
            .component(id: "payment_method", AnyView(
                InlineSelectField(
                    type: .stores, // Reutilizamos el tipo pero lo usaremos para métodos
                    selectedValue: $paymentMethodValue,
                    isExpanded: $paymentMethodExpanded
                )
            ))
        ]
    }

    // Texto de confirmación
    private var confirmationText: String {
        let total = 125.50 // Simulado
        let shipping = 15.0 // Simulado
        let currency = currencyValue ?? "CUP"

        return "Vale, el costo total del producto es \(total) \(currency) y el envío es \(shipping) \(currency), ¿quieres confirmar?"
    }

    // MARK: - Selection Handlers
    private func handleFirstProductSelection() {
        guard firstProductValue != nil else { return }

        // Reiniciar el streaming para mostrar el segundo selector de producto
        startStreaming = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startStreaming = true
        }
    }

    private func handleSecondProductSelection() {
        guard secondProductValue != nil else { return }

        // Verificar si TAMBIÉN está seleccionado el vendedor
        // Solo avanzar cuando AMBOS estén seleccionados
        guard storeValue != nil else { return }

        advanceToPaymentStep()
    }

    private func handleStoreSelection() {
        guard storeValue != nil else { return }

        // Verificar si TAMBIÉN están seleccionados los productos
        // Solo avanzar cuando AMBOS estén seleccionados
        guard firstProductValue != nil && secondProductValue != nil else { return }

        advanceToPaymentStep()
    }

    // Función auxiliar para avanzar al paso de pago
    private func advanceToPaymentStep() {
        // Cuando se completan productos + tienda, navegar a IntroVideo con metodopago
        onComplete()
    }

    private func handleCurrencySelection() {
        guard currencyValue != nil else { return }

        // Verificar si TAMBIÉN está seleccionado el método de pago
        // Solo avanzar cuando AMBOS estén seleccionados
        guard paymentMethodValue != nil else { return }

        advanceToConfirmationStep()
    }

    private func handlePaymentMethodSelection() {
        guard paymentMethodValue != nil else { return }

        // Verificar si TAMBIÉN está seleccionada la moneda
        // Solo avanzar cuando AMBOS estén seleccionados
        guard currencyValue != nil else { return }

        advanceToConfirmationStep()
    }

    // Función auxiliar para avanzar al paso de confirmación
    private func advanceToConfirmationStep() {
        // Cuando se completan moneda + método de pago, navegar a IntroVideo con agradecimiento
        onComplete()
    }

    // MARK: - Animations
    private func startEntranceAnimation() {
        // Comenzar con el step inicial configurado
        currentStep = initialStep
        
        // Si viene del tercer video, mostrar confirmación final sin avatar
        if initialStep == .showingConfirmation {
            isFinalConfirmation = true
            showAvatar = false
            withAnimation(.spring(response: 0.9, dampingFraction: 0.88).delay(0.3)) {
                showBubble = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                startStreaming = true
                state = .streaming
            }
        } else {
            // Avatar del cliente aparece
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.3)) {
                showAvatar = true
            }

            // Burbuja del cliente aparece
            withAnimation(.spring(response: 0.9, dampingFraction: 0.88).delay(0.6)) {
                showBubble = true
            }

            // Streaming empieza
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                startStreaming = true
                state = .streaming
            }
        }
    }

    // MARK: - Helper Functions
    private func closeAllPickers() {
        firstProductExpanded = false
        secondProductExpanded = false
        storeExpanded = false
        currencyExpanded = false
        paymentMethodExpanded = false
    }

    private func confirmOrder() {
        print("✅ Pedido confirmado:")
        print("  - Producto 1: \(firstProductValue ?? "N/A")")
        print("  - Producto 2: \(secondProductValue ?? "N/A")")
        print("  - Vendedor: \(storeValue ?? "N/A")")
        print("  - Moneda: \(currencyValue ?? "N/A")")
        print("  - Método de pago: \(paymentMethodValue ?? "N/A")")
        // Aquí iría la lógica real de confirmación
        dismiss()
    }

    // MARK: - Payment Methods
    private var paymentMethods: [PaymentMethod] {
        [
            PaymentMethod(
                id: "cash_cup",
                name: "Efectivo CUP",
                description: "Pago al recibir",
                imageType: .systemIcon("banknote"),
                color: Color.llegoPrimary,
                currency: "CUP"
            ),
            PaymentMethod(
                id: "cash_usd",
                name: "Efectivo USD",
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
            )
        ]
    }
}

// MARK: - Supporting Types
struct SimpleCurrency: Identifiable, Equatable {
    let id: String
    let name: String
    let flag: String
}

// MARK: - Preview
#Preview("Conversational Search") {
    NavigationStack {
        ConversationalSearchView()
    }
}

#Preview("With Selected Values") {
    struct PreviewWithValues: View {
        @State private var productValue: String? = "Frutas frescas"
        @State private var storeValue: String? = "La Bodeguita"

        var body: some View {
            NavigationStack {
                ConversationalSearchView()
            }
        }
    }

    return PreviewWithValues()
}
