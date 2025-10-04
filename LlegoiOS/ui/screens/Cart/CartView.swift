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
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CartViewModel()
    @State private var navigateToCheckout = false
    @State private var isAnimatingCheckout = false
    @State private var selectedCurrency: Currency = .CUP

    var body: some View {
        NavigationView{
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
           
            
                    
                    // Loading State
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
                        // Lista de productos
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

                            }
                            .padding(.horizontal, 20)
                           
                        }
                        // Insertamos el bottom bar como inset para que el ScrollView no quede oculto
                        .safeAreaInset(edge: .bottom) {
                            VStack(spacing: 12) {
                                // Mensaje de información
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.llegoAccent)

                                    Text("Pago seguro y protegido")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                }

                                Button(action: {
                                    navigateToCheckout = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "cart.fill.badge.plus")
                                            .font(.system(size: 18, weight: .bold))

                                        Text("Proceder al Pago")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))

                                        Spacer()

                                        Text(viewModel.formattedTotal)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .frame(height: 60)
                                    
                                    .cornerRadius(30)
                                   
                                }
                                .buttonStyle(.glassProminent)
                                .tint(Color.llegoPrimary)
                                .shadow(color: Color.llegoAccent.opacity(0.5), radius: 15, x: 0, y: 8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            // Para que el botón quede sobre el teclado cuando aparezca
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                        }
                    }
                }
            
        }
        .navigationTitle("Carrito")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.llegoPrimary)
                        .font(.system(size: 18, weight: .semibold))
                }
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
                                    .foregroundColor(.llegoPrimary)
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
        .fullScreenCover(isPresented: $navigateToCheckout) {
            CheckoutView()
        }
        .onAppear {
            viewModel.loadCart()
        }
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
                presentationMode.wrappedValue.dismiss()
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
