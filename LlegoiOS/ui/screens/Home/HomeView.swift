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
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchExpanded: Bool = false
    @State private var isSearchLoading: Bool = false
    @State private var showSearchResults: Bool = false
    @State private var searchResultsOffset: CGFloat = -50
    @State private var searchDebounceTask: Task<Void, Never>? = nil
    @State private var isFilterSheetPresented: Bool = false

    // Resultados filtrados de búsqueda
    @State private var filteredCategories: [(String, String)] = []
    @State private var filteredSearchProducts: [Product] = []
    @State private var filteredSearchStores: [Store] = []

    // Productos filtrados para la vista principal
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        }
        return viewModel.products.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            product.shop.localizedCaseInsensitiveContains(searchText)
        }
    }
    // Función de búsqueda
    private func performSearch() {
        guard !searchText.isEmpty else {
            filteredCategories = []
            filteredSearchProducts = []
            filteredSearchStores = []
            showSearchResults = false
            return
        }

        isSearchLoading = true
        showSearchResults = false

        // Simular búsqueda de 1 segundo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Buscar categorías
            filteredCategories = semicircularCategories.filter { category in
                category.0.localizedCaseInsensitiveContains(searchText)
            }

            // Buscar productos (máximo 3)
            filteredSearchProducts = mockProducts.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.shop.localizedCaseInsensitiveContains(searchText)
            }.prefix(3).map { $0 }

            // Buscar vendedores (máximo 3)
            filteredSearchStores = mockStores.filter { store in
                store.name.localizedCaseInsensitiveContains(searchText) ||
                (store.address?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.prefix(3).map { $0 }

            isSearchLoading = false
            showSearchResults = true

            // Animación de caída
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                searchResultsOffset = 0
            }
        }
    }

    private func applyCategoryFilter(_ category: String) {
        searchDebounceTask?.cancel()
        searchText = category
        isSearchExpanded = true
        isSearchFocused = false
        isSearchLoading = true
        showSearchResults = false
        searchResultsOffset = -50
        performSearch()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo degradado que se expande suavemente al aparecer
                SharedGradientBackground(expansionProgress: gradientExpansion)
                    .onTapGesture {
                        // Cerrar búsqueda al tocar fuera
                        if isSearchExpanded {
                            isSearchFocused = false
                            searchText = ""
                        }
                    }

                VStack(spacing: 0) {
                    // Card de búsqueda con skeleton o resultados
                    if isSearchExpanded {
                        ScrollView {
                            VStack(spacing: 0) {
                                if isSearchLoading {
                                    // Skeleton con solo 3 items
                                    searchSkeletonCard
                                } else if showSearchResults {
                                    // Resultados de búsqueda con las 3 secciones
                                    searchResultsView
                                        .offset(y: searchResultsOffset)
                                        .opacity(showSearchResults ? 1 : 0)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                    }

                    // Contenido principal
                    if !isSearchExpanded {
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
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Barra de búsqueda
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("Buscar productos...", text: $searchText)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .focused($isSearchFocused)

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }

                        if isSearchExpanded {
                            Button(action: {
                                isSearchFocused = false
                                searchText = ""
                            }) {
                                Text("Cancelar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.llegoPrimary)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    // Botón de carrito (ocultar cuando búsqueda está expandida)
                    if !isSearchExpanded {
                        Button(action: {
                            navigateToCart = true
                        }) {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.llegoPrimary)
                        }
                    }
                }
//                ToolbarItem(placement: .bottomBar) {
//                    Button {
//                        isFilterSheetPresented = true
//                    } label: {
//                        Image(systemName: "line.3.horizontal.decrease.circle")
//                            .font(.system(size: 20, weight: .semibold))
//                    }
////                    .accessibilityLabel("Filtrar categorías")
//                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
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
            .onChange(of: isSearchFocused) { focused in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isSearchExpanded = focused
                }

                if !focused {
                    // Limpiar resultados al cerrar
                    isSearchLoading = false
                    showSearchResults = false
                    filteredCategories = []
                    filteredSearchProducts = []
                    filteredSearchStores = []
                    searchDebounceTask?.cancel()
                }
            }
            .onChange(of: searchText) { newValue in
                // Cancelar búsqueda anterior
                searchDebounceTask?.cancel()

                if !newValue.isEmpty {
                    if !isSearchExpanded {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isSearchExpanded = true
                        }
                    }

                    // Debounce de 1 segundo
                    searchDebounceTask = Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
                        await MainActor.run {
                            performSearch()
                        }
                    }
                } else {
                    // Limpiar resultados si el texto está vacío
                    isSearchLoading = false
                    showSearchResults = false
                    filteredCategories = []
                    filteredSearchProducts = []
                    filteredSearchStores = []
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
        .sheet(isPresented: $isFilterSheetPresented) {
            CategoryFilterSheet(
                categories: semicircularCategories
            ) { category in
                isFilterSheetPresented = false
                applyCategoryFilter(category)
            }
            .presentationDetents([.fraction(0.3), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Products Grid
    private var productsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    alignment: .center,
                    spacing: 18
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
                        .aspectRatio(0.68, contentMode: .fit)
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
            }
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

    // MARK: - Search Skeleton Card (solo 3 items compactos)
    private var searchSkeletonCard: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 10) {
                    // Imagen skeleton cuadrada con esquinas redondeadas
                    Circle()
                        .fill(Color.llegoPrimary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .shimmer()

                    // Contenido skeleton
                    VStack(alignment: .leading, spacing: 4) {
                        // Título
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoPrimary.opacity(0.2))
                            .frame(height: 12)
                            .shimmer()

                        // Subtítulo
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoPrimary.opacity(0.2))
                            .frame(height: 10)
                            .frame(maxWidth: 140)
                            .shimmer()

                        // Precio
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoPrimary.opacity(0.2))
                            .frame(height: 13)
                            .frame(maxWidth: 80)
                            .shimmer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .padding(12)
        .cornerRadius(12)
        .glassEffect(.regular.interactive(),in: .rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    // MARK: - Search Results View (3 secciones compactas en un solo contenedor)
    private var searchResultsView: some View {
        let hasCategories = !filteredCategories.isEmpty
        let hasProducts = !filteredSearchProducts.isEmpty
        let hasStores = !filteredSearchStores.isEmpty
        let hasAnyResults = hasCategories || hasProducts || hasStores

        return Group {
            if hasAnyResults {
                VStack(spacing: 20) {
                    // Sección 1: Categorías (solo si hay resultados)
                    if hasCategories {
                        categoriesSection
                    }

                    // Divider (solo si hay categorías y otros resultados)
                    if hasCategories && (hasProducts || hasStores) {
                        Divider()
                            .padding(.horizontal, 12)
                    }

                    // Sección 2: Productos (solo si hay resultados, máximo 3)
                    if hasProducts {
                        productsSection
                    }

                    // Divider (solo si hay productos y vendedores)
                    if hasProducts && hasStores {
                        Divider()
                            .padding(.horizontal, 12)
                    }

                    // Sección 3: Vendedores (solo si hay resultados)
                    if hasStores {
                        sellersSection
                    }
                }
                .padding(.vertical, 16)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                .glassEffect(.regular.interactive(),in: .rect(cornerRadius: 12))
            } else {
                // Sin resultados
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.gray)

                    Text("No se encontraron resultados")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.llegoPrimary)

                    Text("Intenta con otra búsqueda")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)
                .glassEffect(.regular.interactive(),in: .rect(cornerRadius: 12))
            }
        }
    }

    // MARK: - Categorías Section (compacta)
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categorías")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredCategories, id: \.0) { category in
                        SimpleCategoryItem(
                            text: category.0,
                            imageName: category.1,
                            imageSize: 55
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    // MARK: - Productos Section (compacta, máximo 3)
    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Productos")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                ForEach(filteredSearchProducts, id: \.id) { product in
                    ProductListItem(product: product, compact: true)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Vendedores Section (compacta, máximo 3)
    private var sellersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vendedores")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                ForEach(filteredSearchStores, id: \.id) { store in
                    SellerListItem(store: store, compact: true)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Mock Data
    // Categorías usando las mismas imágenes que SemicircularSlider
    private let semicircularCategories = [
        ("Italiana", "italiana"),
        ("Platos Fuertes", "platos_fuertes"),
        ("Vegetariana", "vegetariana"),
        ("Batidos y Cócteles", "batidos_y_cocteles"),
        ("Bebidas Enlatadas", "bebidas_enlatadas"),
        ("Botellas", "botellas")
    ]

    private let mockProducts = [
        Product(
            id: "1",
            name: "Aguacate orgánico",
            shop: "FreshMart",
            weight: "500g",
            price: "$2.50",
            imageUrl: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400"
        ),
        Product(
            id: "2",
            name: "Mango maduro",
            shop: "EcoFruit",
            weight: "1kg",
            price: "$3.99",
            imageUrl: "https://images.unsplash.com/photo-1553279768-865429fa0078?w=400"
        ),
        Product(
            id: "3",
            name: "Plátano verde",
            shop: "TropicalFresh",
            weight: "1kg",
            price: "$1.99",
            imageUrl: "https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=400"
        )
    ]

    private let mockStores = [
        Store(
            id: "1",
            name: "FreshMart Premium",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
            address: "Calle 23 #456, Vedado",
            rating: 4.8
        ),
        Store(
            id: "2",
            name: "EcoFruit Orgánico",
            etaMinutes: 30,
            logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
            address: "Av. 5ta #789, Miramar",
            rating: 4.6
        ),
        Store(
            id: "3",
            name: "TropicalFresh Market",
            etaMinutes: 20,
            logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
            address: "Calle 10 #234, Plaza",
            rating: 4.9
        )
    ]
}

private struct CategoryFilterSheet: View {
    let categories: [(String, String)]
    let onCategorySelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Filtrar por categoría")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.0) { category in
                        FilterCategoryChip(
                            title: category.0,
                            imageName: category.1,
                            action: {
                                onCategorySelect(category.0)
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
    }
}

private struct FilterCategoryChip: View {
    let title: String
    let imageName: String
    let action: () -> Void

    private let imageSize: CGFloat = 42

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
