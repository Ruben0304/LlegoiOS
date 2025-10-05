import SwiftUI
import CoreLocation


struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var orderManager = OrderManager.shared
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var isProcessingPayment = false
    @State private var navigateToConfirmation = false
    @State private var deliveryLocation = "Calle 23 #456, Vedado, La Habana"
    @State private var deliveryPrice = "150 CUP"

    let paymentMethods: [PaymentMethod] = [
        PaymentMethod(
            id: "cash_cup",
            name: "Efectivo CUP",
            description: "Pago al recibir el pedido",
            icon: "banknote",
            color: Color.llegoPrimary,
            currency: "CUP"
        ),
        PaymentMethod(
            id: "cash_usd",
            name: "Efectivo USD",
            description: "Pago al recibir el pedido",
            icon: "dollarsign.circle",
            color: Color.llegoAccent,
            currency: "USD"
        ),
        PaymentMethod(
            id: "bank_transfer",
            name: "Transferencia Bancaria",
            description: "Transferencia CUP a cuenta bancaria",
            icon: "building.columns",
            color: Color.llegoSecondary,
            currency: "CUP"
        ),
        PaymentMethod(
            id: "credit_card",
            name: "Tarjeta de Crédito",
            description: "Visa/Mastercard USD",
            icon: "creditcard",
            color: Color.llegoTertiary,
            currency: "USD"
        ),
        PaymentMethod(
            id: "qvapay",
            name: "QvaPay",
            description: "Pago digital rápido y seguro",
            icon: "qrcode",
            color: Color(red: 0.2, green: 0.6, blue: 0.9),
            currency: "CUP/USD"
        ),
        PaymentMethod(
            id: "tropipay",
            name: "TropiPay",
            description: "Cartera digital cubana",
            icon: "wallet.pass",
            color: Color(red: 0.9, green: 0.4, blue: 0.1),
            currency: "CUP/USD"
        )
    ]

    var body: some View {
        NavigationView {
            ZStack {
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

                ScrollView {
                    VStack(spacing: 0) {
                        // Header con información del pedido
                        orderSummarySection

                        // Sección de precio de envío
                        deliverySection

                        // Métodos de pago
                        paymentMethodsSection

                        // Botón de procesar pago
                        processPaymentButton

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.llegoPrimary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "truck.box")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.llegoAccent)
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToConfirmation) {
            OrderConfirmationView(
                deliveryLocation: deliveryLocation,
                selectedPaymentMethod: selectedPaymentMethod?.name ?? ""
            )
        }
    }

    private var orderSummarySection: some View {
        VStack(spacing: 20) {
            // Imagen y detalles del pedido
            HStack(spacing: 16) {
                // Imagen del producto principal
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.llegoAccent.opacity(0.3), Color.llegoPrimary.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.llegoPrimary)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tu pedido")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    Text("3 productos • Restaurante Cubano")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)

                    HStack {
                        Text("Total:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.llegoPrimary)

                        Spacer()

                        Text("$45.50 USD")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoAccent)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    private var deliverySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Ícono de ubicación animado
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.llegoAccent.opacity(0.2), Color.llegoPrimary.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "location.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.llegoAccent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Envío hasta tu ubicación")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.llegoAccent)

                        Text(deliveryLocation)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.llegoSecondary)

                        Text("30-45 min")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Spacer()

                        // Precio de envío destacado
                        Text(deliveryPrice)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.llegoAccent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.llegoAccent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .overlay(
                        // Borde elegante con gradiente
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.llegoAccent.opacity(0.3), Color.llegoPrimary.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Mensaje informativo elegante
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.llegoAccent)

                Text("El precio de envío puede variar según la distancia y condiciones del tráfico")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 4)
        }
    }

    private var paymentMethodsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Métodos de Pago")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                Image(systemName: "lock.shield")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.llegoAccent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            LazyVStack(spacing: 12) {
                ForEach(paymentMethods, id: \.id) { method in
                    PaymentMethodCard(
                        method: method,
                        isSelected: selectedPaymentMethod?.id == method.id
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedPaymentMethod = method
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var processPaymentButton: some View {
        VStack(spacing: 16) {
            if let selected = selectedPaymentMethod {
                Text("Pagarás con \(selected.name)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .transition(.scale.combined(with: .opacity))
            }

            Button(action: processPayment) {
                HStack(spacing: 12) {
                    if isProcessingPayment {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 18, weight: .bold))

                        Text("Procesar Pedido")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if selectedPaymentMethod != nil && !isProcessingPayment {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.llegoAccent, Color.llegoPrimary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.gray.opacity(0.5)
                        }
                    }
                )
                .cornerRadius(28)
                .shadow(
                    color: selectedPaymentMethod != nil ? Color.llegoAccent.opacity(0.4) : Color.clear,
                    radius: 12, x: 0, y: 6
                )
                .scaleEffect(isProcessingPayment ? 0.98 : 1.0)
            }
            .disabled(selectedPaymentMethod == nil || isProcessingPayment)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedPaymentMethod)
            .animation(.easeInOut(duration: 0.2), value: isProcessingPayment)
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
    }


    private func processPayment() {
        guard let paymentMethod = selectedPaymentMethod else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessingPayment = true
        }

        // Simular procesamiento de pago
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessingPayment = false

            // Iniciar pedido con OrderManager
            startOrder(paymentMethod: paymentMethod)

            // Navegar a confirmación
            navigateToConfirmation = true
        }
    }

    private func startOrder(paymentMethod: PaymentMethod) {
        // Productos de ejemplo (en producción, vendrían del carrito)
        let products: [ActiveOrder.OrderProduct] = [
            ActiveOrder.OrderProduct(
                id: "1",
                name: "Pizza Margarita",
                imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png",
                quantity: 2,
                price: 15.50
            ),
            ActiveOrder.OrderProduct(
                id: "2",
                name: "Tres Leches",
                imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (13).png",
                quantity: 1,
                price: 8.00
            ),
            ActiveOrder.OrderProduct(
                id: "3",
                name: "Batido de Mamey",
                imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (17).png",
                quantity: 1,
                price: 22.00
            )
        ]

        // Coordenadas del restaurante (origen)
        let restaurantCoordinates = CLLocationCoordinate2D(
            latitude: 23.1150,
            longitude: -82.3680
        )

        // Coordenadas de entrega (destino)
        let deliveryCoordinates = CLLocationCoordinate2D(
            latitude: 23.1136,
            longitude: -82.3666
        )

        // Iniciar el pedido con simulación de 2 minutos
        orderManager.startOrder(
            products: products,
            totalAmount: 45.50,
            currency: "USD",
            deliveryLocation: deliveryLocation,
            deliveryCoordinates: deliveryCoordinates,
            restaurantLocation: "Restaurante El Cubano, Centro Habana",
            restaurantCoordinates: restaurantCoordinates,
            paymentMethod: paymentMethod.name
        )

        print("✅ CheckoutView: Pedido iniciado con simulación de 2 minutos")
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Ícono del método de pago
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(method.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: method.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(method.color)
                }

                // Información del método
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    Text(method.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Text(method.currency)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(method.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(method.color.opacity(0.1))
                        .cornerRadius(6)
                }

                Spacer()

                // Indicador de selección
                ZStack {
                    Circle()
                        .stroke(isSelected ? method.color : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(method.color)
                            .frame(width: 14, height: 14)
                            .scaleEffect(isSelected ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .stroke(
                        isSelected ? method.color.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
                    .shadow(
                        color: isSelected ? method.color.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 10 : 5,
                        x: 0, y: isSelected ? 5 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentMethod: Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let currency: String

    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        return lhs.id == rhs.id
    }
}

#Preview {
    CheckoutView()
}
