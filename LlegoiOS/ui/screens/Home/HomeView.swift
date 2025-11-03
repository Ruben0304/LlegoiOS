import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var productCounts: [String: Int] = [:]
    @State private var navigateToCart = false
    @State private var navigateToWallet = false
    @State private var selectedProduct: Product? = nil
    @State private var navigateToProfile = false
    @State private var animationDelay: Double = 0
    @State private var gradientExpansion: Double = 0.0
    @State private var searchText = ""

    // Productos filtrados por búsqueda
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        }
        return viewModel.products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            product.shop.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo degradado que se expande suavemente al aparecer
                SharedGradientBackground(expansionProgress: gradientExpansion)

                VStack(spacing: 0) {
                    // Ubicación
                   

                    // Contenido principal
                    if viewModel.isLoading {
                        loadingState
                    } else if case .error(let message) = viewModel.state {
                        errorState(message: message)
                    } else if filteredProducts.isEmpty {
                        emptyState
                    } else {
                        productsGrid
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {

                    // Barra de búsqueda personalizada
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("Buscar productos...", text: $searchText)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                }
                ToolbarSpacer(.fixed,placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    // Botón de carrito
                    Button(action: {
                        navigateToCart = true
                    }) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.llegoPrimary)
                    
                        }
                    
                }
                
                
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Animar el gradiente verde bajando suavemente
                withAnimation(.easeInOut(duration: 1.2)) {
                    gradientExpansion = 1.0
                }

                if case .idle = viewModel.state {
                    viewModel.loadHomeData()
                }
                walletViewModel.loadBalance()
                productCounts = cartManager.localItems.reduce(into: [:]) { result, item in
                    result[item.productId] = item.quantity
                }
            }
            .onReceive(cartManager.$localItems) { items in
                productCounts = items.reduce(into: [:]) { result, item in
                    result[item.productId] = item.quantity
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToCart) {
            NavigationView {
                CartView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(isPresented: $navigateToWallet) {
            NavigationView {
                WalletView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .navigationDestination(item: $selectedProduct) { product in
            TestProductView(product: product)
        }
        .fullScreenCover(isPresented: $navigateToProfile) {
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    // MARK: - Products Grid
    private var productsGrid: some View {
        ScrollView {
//            VStack(spacing: 8) {
//                Text("Ubicación actual")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.white.opacity(0.9))
//
//                HStack(spacing: 6) {
//                    Image(systemName: "location.fill")
//                        .foregroundColor(.white)
//                        .font(.system(size: 14))
//
//                    Text("La Habana, Cuba")
//                        .font(.system(size: 18, weight: .bold, design: .rounded))
//                        .foregroundColor(.white)
//                }
//            }
//            .padding(.top, 16)
//            .padding(.bottom, 20)

            // Sección de categorías
//            CategoryGridSection { category in
//                print("Categoría seleccionada: \(category)")
//                // TODO: Navegar a la vista de categoría o filtrar productos
//            }
//            .padding(.top, 20)
//            .padding(.bottom, 16)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .center,
                spacing: 20
            ) {
                ForEach(Array(filteredProducts.enumerated()), id: \.element.id) { index, product in
                    ProductCard(
                        product: product,
                        count: Binding(
                            get: { productCounts[product.id] ?? 0 },
                            set: { newValue in
                                if newValue > 0 {
                                    productCounts[product.id] = newValue
                                } else {
                                    productCounts.removeValue(forKey: product.id)
                                }
                            }
                        ),
                        onIncrement: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                productCounts[product.id] = (productCounts[product.id] ?? 0) + 1
                            }
                        },
                        onDecrement: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                let currentCount = productCounts[product.id] ?? 0
                                if currentCount > 0 {
                                    if currentCount == 1 {
                                        productCounts.removeValue(forKey: product.id)
                                    } else {
                                        productCounts[product.id] = currentCount - 1
                                    }
                                }
                            }
                        }
                    )
                    .aspectRatio(155.0/310.0, contentMode: .fit)
                    .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                    .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                    .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.8)
                        .delay(0.8 + Double(index) * 0.08),
                        value: animationDelay
                    )
                    .onTapGesture {
                        selectedProduct = product
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .onAppear {
            animationDelay = Double(filteredProducts.count) * 0.1 + 0.1
        }
        .onChange(of: filteredProducts.count) { _ in
            animationDelay = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animationDelay = Double(filteredProducts.count) * 0.1 + 0.1
            }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            LottieView(name: "loader")
                .frame(width: 150, height: 150)
            Text("Cargando productos...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") {
                viewModel.loadHomeData()
            }
            .frame(height: 50)
            .frame(maxWidth: 200)
            .buttonStyle(.glassProminent)
            .tint(.llegoPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

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
                    .frame(width: 180, height: 180)

                Image(systemName: searchText.isEmpty ? "cart" : "magnifyingglass")
                    .font(.system(size: 70, weight: .light))
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
            .padding(.bottom, 8)

            Text(searchText.isEmpty ? "No hay productos disponibles" : "No se encontraron resultados")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.llegoPrimary)
                .multilineTextAlignment(.center)

            Text(searchText.isEmpty ? "Vuelve a revisar más tarde" : "Intenta con otra búsqueda")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
