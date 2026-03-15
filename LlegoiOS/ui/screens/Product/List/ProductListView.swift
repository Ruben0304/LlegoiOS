import SwiftUI

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct ProductListView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var productCounts: [String: Int] = [:]
    @State private var showFiltersSheet = false
    @State private var showFavoritesSheet = false
    @State private var animationDelay: Double = 0
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchPresented: Bool = false
    @State private var selectedProductId: String?
    @State private var showCart = false

    // Parámetros opcionales para filtrado inicial
    let initialCategory: String?
    let initialBranchId: String?
    let branchName: String?
    let storeGradient: ExtractedGradient?

    // ViewModel propio para cuando hay branchId (no compartido)
    @StateObject private var branchViewModel = ProductListViewModel()

    init(viewModel: ProductListViewModel? = nil, category: String? = nil, branchId: String? = nil, branchName: String? = nil, storeGradient: ExtractedGradient? = nil) {
        // Si hay branchId, usaremos branchViewModel (StateObject propio)
        // Si no hay branchId, usamos el viewModel pasado o creamos uno nuevo
        self._viewModel = ObservedObject(wrappedValue: viewModel ?? ProductListViewModel())
        self.initialCategory = category
        self.initialBranchId = branchId
        self.branchName = branchName
        self.storeGradient = storeGradient
    }

    // ViewModel activo: usa branchViewModel si hay branchId, sino usa el viewModel compartido
    private var activeViewModel: ProductListViewModel {
        initialBranchId != nil ? branchViewModel : viewModel
    }

    // Bindings para el ViewModel activo
    private var maxDistanceBinding: Binding<Double> {
        Binding(
            get: { activeViewModel.maxDistance },
            set: { activeViewModel.maxDistance = $0 }
        )
    }

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { activeViewModel.searchQuery },
            set: { activeViewModel.searchQuery = $0 }
        )
    }

    private var totalCartItems: Int {
        productCounts.values.reduce(0, +)
    }

    // MARK: - Refresh Function
    private func refreshProducts() async {
        await withCheckedContinuation { continuation in
            activeViewModel.loadProducts(isRefreshing: true)
            // Wait a bit to allow the animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeGradientBackground(customGradient: storeGradient)
                    .ignoresSafeArea()

                // Contador de resultados
                if !activeViewModel.isLoading {

                }

                // Contenido principal
                if activeViewModel.isLoading {
                    loadingState
                } else if activeViewModel.isSearching {
                    searchSkeletonView
                } else if case .error(let message) = activeViewModel.state {
                    errorState(message: message)
                } else if activeViewModel.filteredProducts.isEmpty {
                    emptyStateScroll
                } else {
                    productsGrid
                }
            }
            .onAppear {
                // Primero configurar los filtros
                if let category = initialCategory {
                    activeViewModel.selectedCategory = category
                }
                if let branchId = initialBranchId {
                    activeViewModel.branchId = branchId
                    print("🏪 ProductListView.onAppear - Setting branchId: \(branchId) on branchViewModel")
                } else {
                    print("🏪 ProductListView.onAppear - No branchId (general product list)")
                }

                // Cargar categorías dinámicamente desde el backend
                activeViewModel.loadCategories()

                // Forzar recarga cuando hay branchId para asegurar que se carguen los productos de esa tienda
                print("🏪 ProductListView.onAppear - Calling loadProducts with branchId: \(activeViewModel.branchId ?? "nil"), isRefreshing: \(initialBranchId != nil)")
                activeViewModel.loadProducts(isRefreshing: initialBranchId != nil)
            }
            .sheet(isPresented: $showFiltersSheet) {
                FiltersSheet(
                    maxDistance: maxDistanceBinding,
                    onApply: {
                        showFiltersSheet = false
                        activeViewModel.applyFilters()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFavoritesSheet) {
                if #available(iOS 16.0, *) {
                    NavigationView {
                        FavoritesView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                } else {
                    NavigationView {
                        FavoritesView()
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
            .navigationTitle(branchName ?? "15.40$")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: searchQueryBinding,
                isPresented: $isSearchPresented,
                placement: initialBranchId != nil ? .navigationBarDrawer(displayMode: .always) : .toolbar,
                prompt: "Buscar productos..."
            )
            .onSubmit(of: .search) {
                // Execute search only when user submits (presses Enter/Search button)
                activeViewModel.executeSearch()
            }
            .onChange(of: activeViewModel.searchQuery) { _, newValue in
                // Clear results when user clears search
                if newValue.isEmpty {
                    activeViewModel.executeSearch()
                }
            }
            .searchFocused($isSearchFocused)
            .toolbar {
                // Show different toolbar items based on context
                if initialBranchId == nil {
                    // Default view: show distance filter
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showFiltersSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 14, weight: .semibold))

                                if activeViewModel.maxDistance < 50 {
                                    Circle()
                                        .fill(gradientManager.currentAccentColor)
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showFavoritesSheet = true
                        }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                        .badge(favoritesManager.favoriteItemCount)
                        .id("favorites-toolbar-badge-\(favoritesManager.favoriteItemCount)")
                        .accessibilityLabel("Favoritos")
                    }

                    ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCart = true
                        }) {
                            Image(systemName: "cart")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                        .badge(cartManager.cartItemCount)
                        .id("cart-toolbar-badge-\(cartManager.cartItemCount)")
                        .accessibilityLabel("Carrito")
                    }
                }

                if initialBranchId == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showFavoritesSheet = true
                        }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                        .badge(favoritesManager.favoriteItemCount)
                        .id("favorites-toolbar-badge-\(favoritesManager.favoriteItemCount)")
                        .accessibilityLabel("Favoritos")
                    }
                }
            }
            .fullScreenCover(item: $selectedProductId) { productId in
                ProductDetailView(productId: productId)
            }
            .fullScreenCover(isPresented: $showCart) {
                CartView()
            }
        }
    }


    // MARK: - Results Counter


    private var productsGrid: some View {
        ScrollView {
            if isSearchFocused {
                categoryScroll
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .center,
                spacing: 20
            ) {
                ForEach(Array(activeViewModel.filteredProducts.enumerated()), id: \.element.id) { index, product in
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
                        },
                        onProductTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedProductId = product.id
                        }
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedProductId = product.id
                    }
                    .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                    .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                    .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.8)
                        .delay(Double(index) * 0.05),
                        value: animationDelay
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .animation(.easeInOut(duration: 0.3), value: isSearchFocused)
        .refreshable {
            await refreshProducts()
        }
        .onAppear {
            animationDelay = Double(activeViewModel.filteredProducts.count) * 0.1 + 0.1
        }
        .onChange(of: activeViewModel.filteredProducts.count) { _, _ in
            animationDelay = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animationDelay = Double(activeViewModel.filteredProducts.count) * 0.1 + 0.1
            }
        }
    }

    // MARK: - Search Skeleton View
    private var searchSkeletonView: some View {
        ScrollView {
            categoryScroll
                .padding(.top, 6)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .center,
                spacing: 20
            ) {
                ForEach(0..<6, id: \.self) { _ in
                    ProductCardSkeleton()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .transition(.opacity)
    }

    private var emptyStateScroll: some View {
        ScrollView {
            if isSearchFocused {
                categoryScroll
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            emptyState
                .padding(.top, 12)
        }
        .animation(.easeInOut(duration: 0.3), value: isSearchFocused)
        .refreshable {
            await refreshProducts()
        }
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 13) {
                ForEach(activeViewModel.categories) { category in
                    let isSelected = category.isAll
                        ? activeViewModel.selectedCategory == nil
                        : activeViewModel.selectedCategory == category.name
                    CategoryChip(
                        title: category.name,
                        icon: category.icon,
                        isSelected: isSelected,
                        isFeatured: category.isFeatured,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if category.isAll || activeViewModel.selectedCategory == category.name {
                                activeViewModel.selectedCategory = nil
                            } else {
                                activeViewModel.selectedCategory = category.name
                            }
                            activeViewModel.applyFilters()
                        },
                        isTinted: initialBranchId == nil
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        .padding(.top, 6)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icono minimalista
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.black)
                .padding(.bottom, 8)

            VStack(spacing: 8) {
                Text("No encontramos productos")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(emptyStateMessage)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(2)
            }

            // Botón de acción
            if activeViewModel.hasActiveFilters || !activeViewModel.searchQuery.isEmpty {
                Button(action: {
                    activeViewModel.searchQuery = ""
                    activeViewModel.selectedCategory = nil
                    activeViewModel.maxDistance = 50
                    activeViewModel.applyFilters()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Limpiar filtros")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(gradientManager.currentAccentColor)
                    .frame(height: 50)
                    .frame(maxWidth: 220)
                }
                .buttonStyle(.glass)
                .padding(.top, 12)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var emptyStateMessage: String {
        if !activeViewModel.searchQuery.isEmpty {
            return "No hay productos que coincidan con \"\(activeViewModel.searchQuery)\". Intenta con otros términos de búsqueda."
        } else if activeViewModel.hasActiveFilters {
            return "No hay productos disponibles con los filtros seleccionados. Prueba ajustar tus criterios de búsqueda."
        } else {
            return "Aún no hay productos disponibles en la tienda. Vuelve a revisar más tarde."
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("Cargando...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
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
                activeViewModel.loadProducts()
            }
            .frame(height: 50)
            .frame(maxWidth: 200)
            .buttonStyle(.glassProminent)
            .tint(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: - Distance Sheet
private struct FiltersSheet: View {
    @Binding var maxDistance: Double
    let onApply: () -> Void
    @State private var tempDistance: Double
    @ObservedObject private var userLocationManager = UserLocationManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    init(maxDistance: Binding<Double>, onApply: @escaping () -> Void) {
        self._maxDistance = maxDistance
        self.onApply = onApply
        self._tempDistance = State(initialValue: maxDistance.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Distancia de búsqueda")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.onSurfaceColor)

                            Text("Ajusta el rango para ver opciones cerca de ti.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 18) {
                            ZStack(alignment: .topLeading) {
                                RadiusMapView(radiusKm: $tempDistance)
                                    .frame(height: 320)
                                    .overlay(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.15),
                                                Color.clear,
                                                Color.black.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .mask(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tempDistance < 50 ? "\(Int(tempDistance)) km" : "Sin límite")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                    Text("Radio actual")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(12)
                            }
                            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)

                            VStack(spacing: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(tempDistance > 1 ? gradientManager.currentAccentColor : .gray.opacity(0.3))
                                        .onTapGesture {
                                            if tempDistance > 1 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    tempDistance = max(1, tempDistance - 1)
                                                }
                                            }
                                        }

                                    Slider(value: $tempDistance, in: 1...50, step: 1)
                                        .tint(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    gradientManager.currentAccentColor,
                                                    Color.llegoAccent
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(tempDistance < 50 ? gradientManager.currentAccentColor : .gray.opacity(0.3))
                                        .onTapGesture {
                                            if tempDistance < 50 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    tempDistance = min(50, tempDistance + 1)
                                                }
                                            }
                                        }
                                }

                                HStack {
                                    Text("1 km")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("50+ km")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }

                                HStack(spacing: 8) {
                                    presetButton(title: "3 km") { tempDistance = 3 }
                                    presetButton(title: "5 km") { tempDistance = 5 }
                                    presetButton(title: "10 km") { tempDistance = 10 }
                                    presetButton(title: "Sin límite") { tempDistance = 50 }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                            )
                        }

                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.llegoAccent)

                            Text("Mientras más cerca busques, menores serán los costos de entrega.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.llegoAccent.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.llegoAccent.opacity(0.18), lineWidth: 1)
                        )
                    }
                    .padding(20)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        tempDistance = 50
                    }) {
                        Text("Restablecer")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.glass)

                    Button(action: {
                        maxDistance = tempDistance
                        // Guardar el radio en el UserLocationManager para persistencia
                        userLocationManager.setSearchRadius(tempDistance < 50 ? tempDistance : nil)
                        onApply()
                    }) {
                        Text("Aplicar distancia")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(gradientManager.currentAccentColor)
                }
                .padding(16)
            }
        }
    }

    private func presetButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(gradientManager.currentAccentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(gradientManager.currentAccentColor.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProductListView()
}
