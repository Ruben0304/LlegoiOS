import SwiftUI

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

    let paymentMethods: [PaymentMethod] = [
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
                // Fondo con gradiente elegante
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.llegoBackground,
                        Color.white,
                        Color.llegoBackground.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 16) {
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

                            // Selector de método de pago
                            // paymentMethodSelector
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.llegoAccent)

                                Text("Pago seguro y protegido")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 12) {
                                Button(action: {
                                    showPaymentMethodPicker = true
                                }) {
                                    HStack(spacing: 8) {
                                        if let method = selectedPaymentMethod {
                                            switch method.imageType {
                                            case .systemIcon(let iconName):
                                                Image(systemName: iconName)
                                                    .font(.system(size: 16, weight: .bold))
                                            case .assetImage(let imageName):
                                                Image(imageName)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 23, height: 23)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Pagar con")
                                                    .font(.system(size: 13, weight: .medium))
                                                Text(method.name)
                                                    .font(.system(size: 14, weight: .bold))
                                            }
                                        } else {
                                            Image(systemName: "creditcard")
                                                .font(.system(size: 16, weight: .bold))
                                            Text("Método de pago")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                }
                                .buttonStyle(.glass)

                                Button(action: {
                                    processPayment()
                                }) {
                                    HStack(spacing: 4) {
                                        Text("Pagar")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                        Text(viewModel.formattedTotal)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                }
                                .disabled(selectedPaymentMethod == nil)
                                .opacity(selectedPaymentMethod == nil ? 0.5 : 1.0)
                                .buttonStyle(.glassProminent)
                                .tint(.llegoPrimary)
                            }
                            .frame(height: 60)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        .onAppear {
            viewModel.loadCart()
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
        guard let paymentMethod = selectedPaymentMethod else { return }

        print("💳 Procesando pago con: \(paymentMethod.name) - \(paymentMethod.currency)")
        print("💰 Total: \(viewModel.formattedTotal)")

        // Aquí iría la lógica real de procesamiento de pago
        // Por ahora solo imprimimos en consola
    }

    

    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icono grande animado
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.llegoAccent.opacity(0.2), Color.llegoPrimary.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "cart")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.llegoPrimary.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text("Tu carrito está vacío")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Text("Agrega productos para comenzar tu pedido")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
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
                .shadow(color: Color.llegoAccent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.top, 16)

            Spacer()
        }
    }

    private var priceBreakdown: some View {
        VStack(spacing: 16) {
            // Subtotal
            HStack {
                Text("Subtotal")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                Text(viewModel.formattedSubtotal)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }

            // Envío
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoAccent)

                    Text("Envío")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Text(viewModel.formattedDeliveryFee)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }

            shippingTipCard

            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 4)

            // Total
            HStack {
                Text("Total")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                Text(viewModel.formattedTotal)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoAccent)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.llegoAccent.opacity(0.3), Color.llegoPrimary.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        )
        .padding(.top, 8)
    }

    private var shippingTipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.llegoAccent.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.llegoAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tip")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
                    .textCase(.uppercase)

                Button(action: {
                    navigateToPlans = true
                }) {
                    (Text("Recomendamos elegir productos de un mismo vendedor para hacer más barato el envío o ")
                        .foregroundColor(.gray)
                        .font(.system(size: 13, weight: .medium)) +
                     Text("suscribirse")
                        .foregroundColor(.llegoAccent)
                        .font(.system(size: 13, weight: .semibold))
                        .underline()
                    )
                    .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.llegoBackground.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.llegoAccent.opacity(0.15), lineWidth: 1)
                )
        )
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
                // Fondo
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color.llegoBackground,
//                        Color.white
//                    ]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "creditcard.circle.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.llegoAccent)

                            Text("Selecciona tu método de pago")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.llegoPrimary)

                            Text("Elige cómo quieres pagar tu pedido")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
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
                        .padding(.horizontal, 20)
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
            HStack(spacing: 16) {
                // Icono del método
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(method.color.opacity(0.1))
                        .frame(width: 55, height: 55)

                    switch method.imageType {
                    case .systemIcon(let iconName):
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(method.color)
                    case .assetImage(let imageName):
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                }

                // Información del método
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    Text(method.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    // Moneda
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .font(.system(size: 11, weight: .medium))
                        Text(method.currency)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(method.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(method.color.opacity(0.12))
                    .cornerRadius(6)
                }

                Spacer()

                // Indicador de selección
                ZStack {
                    Circle()
                        .stroke(isSelected ? method.color : Color.gray.opacity(0.3), lineWidth: 2.5)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(method.color)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected ? method.color.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? method.color.opacity(0.25) : Color.black.opacity(0.06),
                        radius: isSelected ? 12 : 6,
                        x: 0, y: isSelected ? 6 : 3
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
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
            // Imagen del producto - más pequeña
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
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.llegoBackground.opacity(0.5))
            )

            // Información del producto - compacta
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundColor(.llegoPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.shop)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    Text("•")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)

                    Text(item.weight)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.llegoAccent)
                }

                // Precio y total
                HStack(spacing: 6) {
                    Text(item.formattedPrice)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)

                    Text("× \(item.quantity)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.llegoPrimary)

                    Text("=")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)

                    Text(item.formattedItemTotal)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoAccent)
                }
            }

            Spacer()

            // Controles compactos - horizontal
            VStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }

                // Controles de cantidad horizontales
                HStack(spacing: 6) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.llegoPrimary)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(Color.llegoBackground)
                            )
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .frame(width: 22)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.llegoPrimary)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(Color.llegoAccent.opacity(0.2))
                            )
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    CartView()
}
