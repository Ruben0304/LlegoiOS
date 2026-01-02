import SwiftUI
import MapKit

// MARK: - View Mode
enum ShopViewMode {
    case list    // Modo listado: stories + listado de tiendas
    case map     // Modo mapa: solo mapa a pantalla completa
}

struct ShopTabLandingView: View {
    @StateObject private var viewModel = ShopTabLandingViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchExpanded = false
    @State private var isMapFullScreen = false
    @State private var isSearchLoading: Bool = false
    @State private var showSearchResults: Bool = false
    @State private var searchResultsOffset: CGFloat = -50
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    // Modo de visualización
    @State private var viewMode: ShopViewMode = .map

    // Resultados filtrados de búsqueda (solo vendedores)
    @State private var filteredSearchStores: [StoreWithCoordinates] = []

    // Selección de vendedor
    @State private var selectedStore: StoreWithCoordinates? = nil
    
    // Navegación
    @State private var navigationDestination: NavigationDestination? = nil
    @State private var pendingDestination: NavigationDestination? = nil

    // Región del mapa compartida
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1345, longitude: -82.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                // WelcomeGradientBackground()
                //     .ignoresSafeArea()

                // Contenido según el modo de visualización
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        LottieView(dotLottieName: "loader")
                            .frame(width: 150, height: 150)
                        Text("Cargando tiendas...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else if viewMode == .list {
                    // MODO LISTADO: Lista de tiendas con productos
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(viewModel.stores, id: \.id) { store in
                                StoreProductsCard(
                                    store: store,
                                    products: viewModel.products(for: store.id),
                                    isLoadingProducts: viewModel.isLoadingProductsFor(storeId: store.id),
                                    onStoreTap: {
                                        selectedStore = store
                                    },
                                    onProductTap: { product in
                                        // Navigate to product detail
                                        navigationDestination = .shop(branchId: store.id, branchName: store.name)
                                    },
                                    onFavoriteTap: { product in
                                        // Toggle favorite - handled by card's internal FavoritesManager
                                        FavoritesManager.shared.toggleFavorite(productId: product.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    // MODO MAPA: Solo mapa a pantalla completa
                    FullScreenMapView(
                        mapRegion: $mapRegion,
                        stores: viewModel.stores,
                        onStoreSelected: { store in
                            selectedStore = store
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                // Card de búsqueda como overlay flotante (visible en ambos modos)
                if isSearchExpanded {
                    VStack {
                        ScrollView {
                            VStack(spacing: 0) {
                                if isSearchLoading {
                                    // Skeleton con solo 3 items
                                    searchSkeletonCard
                                } else if showSearchResults {
                                    // Resultados de búsqueda (solo vendedores)
                                    searchResultsView
                                        .offset(y: searchResultsOffset)
                                        .opacity(showSearchResults ? 1 : 0)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 16)

                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .zIndex(10) // Asegurar que esté sobre el contenido
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    searchToolbar
                }
                ToolbarSpacer(.fixed)
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            viewMode = viewMode == .list ? .map : .list
                        }
                    }) {
                        Image(systemName: viewMode == .list ? "map.fill" : "list.bullet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: isSearchFocused) { focused in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isSearchExpanded = focused
                }

                if !focused {
                    // Limpiar resultados al cerrar
                    isSearchLoading = false
                    showSearchResults = false
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
                    filteredSearchStores = []
                }
            }
            .navigationDestination(item: $navigationDestination) { destination in
                switch destination {
                case .detail(let store):
                    StoreDetailView(store: store)
                case .shop(let branchId, let branchName):
                    ShopView(branchId: branchId, branchName: branchName)
                case .home:
                    HomeView()
                }
            }
            .sheet(item: $selectedStore, onDismiss: {
                // Navegación segura una vez que el sheet se ha cerrado completamente
                if let destination = pendingDestination {
                    // Un pequeño delay técnico asegura que el ciclo de renderizado esté listo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         navigationDestination = destination
                         pendingDestination = nil
                    }
                }
            }) { store in
                StoreOptionsModal(
                    store: store,
                    onViewProfile: {
                        pendingDestination = .detail(store.toStore())
                        selectedStore = nil // Esto cierra el sheet e invoca onDismiss
                    },
                    onViewProducts: {
                        pendingDestination = .shop(branchId: store.id, branchName: store.name)
                        selectedStore = nil // Esto cierra el sheet e invoca onDismiss
                    }
                )
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .interactiveDismissDisabled(false)
            }
            .onAppear {
                viewModel.loadStores()
            }
        }
    }

    // MARK: - Función de búsqueda
    private func performSearch() {
        guard !searchText.isEmpty else {
            filteredSearchStores = []
            showSearchResults = false
            return
        }

        isSearchLoading = true
        showSearchResults = false

        // Buscar usando el ViewModel
        viewModel.searchStores(query: searchText) { results in
            filteredSearchStores = results
            isSearchLoading = false
            showSearchResults = true

            // Animación de caída
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                searchResultsOffset = 0
            }
        }
    }

    // MARK: - Animar mapa a ubicación de tienda
    private func animateToStore(_ store: StoreWithCoordinates) {
        // Cerrar búsqueda
        isSearchFocused = false
        searchText = ""
        isSearchExpanded = false
        showSearchResults = false

        // Cambiar a modo mapa
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            viewMode = .map
        }

        // Animar mapa a la ubicación con animación fluida y lenta
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                mapRegion = MKCoordinateRegion(
                    center: store.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            }
        }

        // El sheet se abre automáticamente cuando selectedStore tiene valor
    }

    private var searchToolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 14))

            TextField("Buscar vendedores...", text: $searchText)
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

    // MARK: - Search Skeleton Card (solo 3 items compactos)
    private var searchSkeletonCard: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 10) {
                    // Imagen skeleton circular
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

                        // Info
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

    // MARK: - Search Results View (solo vendedores)
    private var searchResultsView: some View {
        let hasStores = !filteredSearchStores.isEmpty

        return Group {
            if hasStores {
                VStack(spacing: 20) {
                    // Sección de Vendedores
                    sellersSection
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

                    Text("No se encontraron vendedores")
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

    // MARK: - Vendedores Section (compacta, máximo 3)
    private var sellersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vendedores")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                ForEach(filteredSearchStores, id: \.id) { store in
                    Button(action: {
                        selectedStore = store
                        animateToStore(store)
                    }) {
                        SellerListItem(store: store.toStore(), compact: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
        }
    }

}

// MARK: - StoreWithCoordinates
struct StoreWithCoordinates: Identifiable {
    let id: String
    let name: String
    let etaMinutes: Int
    let logoUrl: String
    let bannerUrl: String
    let address: String?
    let rating: Double?
    let coordinate: CLLocationCoordinate2D

    func toStore() -> Store {
        Store(
            id: id,
            name: name,
            etaMinutes: etaMinutes,
            logoUrl: logoUrl,
            bannerUrl: bannerUrl,
            address: address,
            rating: rating
        )
    }
}

// MARK: - StoreOptionsModal (Native iOS Sheet Style)
private struct StoreOptionsModal: View {
    let store: StoreWithCoordinates
    let onViewProfile: () -> Void
    let onViewProducts: () -> Void
    var onDismiss: (() -> Void)? = nil
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header con imagen del negocio
            ZStack(alignment: .bottom) {
                // Banner con gradiente elegante
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 180)
                                .clipped()
                        case .empty, .failure:
                            Image("generic_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 180)
                                .clipped()
                        @unknown default:
                            Image("generic_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: 180)
                                .clipped()
                        }
                    }
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(.systemBackground).opacity(0.3),
                                Color(.systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 180)
                
                // Logo flotante
                AsyncImage(url: URL(string: store.logoUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Image("generic_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    @unknown default:
                        Image("generic_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(.systemBackground), lineWidth: 4)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .offset(y: 44)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1 : 0)
            }
            
            Spacer().frame(height: 56)
            
            // MARK: - Información del negocio
            VStack(spacing: 8) {
                Text(store.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let address = store.address {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(address)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 10)
            
            Spacer().frame(height: 20)
            
            // MARK: - Pills de información
            HStack(spacing: 16) {
                // Rating
                if let rating = store.rating {
                    InfoPill(
                        icon: "star.fill",
                        iconColor: .orange,
                        value: String(format: "%.1f", rating),
                        label: "Rating"
                    )
                }
                
                // Tiempo de entrega
                InfoPill(
                    icon: "clock.fill",
                    iconColor: .llegoAccent,
                    value: "\(store.etaMinutes)",
                    label: "min"
                )
                
                // Estado
                InfoPill(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    value: "Abierto",
                    label: "Ahora"
                )
            }
            .padding(.horizontal, 24)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 15)
            
            Spacer().frame(height: 28)
            
            // MARK: - Botones de acción estilo Apple
            VStack(spacing: 12) {
                // Botón primario - Ver productos
                Button(action: onViewProducts) {
                    HStack(spacing: 10) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ver Productos")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Botón secundario - Ver perfil
                Button(action: onViewProfile) {
                    HStack(spacing: 10) {
                        Image(systemName: "storefront")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ver Perfil de Tienda")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Color(.secondarySystemBackground)
                    )
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 20)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            
            Spacer().frame(height: 16)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Info Pill Component
private struct InfoPill: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

private struct RadialShopMapView: View {
    @Binding var isFullScreen: Bool

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1345, longitude: -82.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    @State private var isPulsing = false
    @State private var isMapExpanded = false
    @State private var inactivityTimer: Timer?

    private let shopPins: [ShopPin] = [
        ShopPin(
            coordinate: CLLocationCoordinate2D(latitude: 23.1355, longitude: -82.3600),
            type: .restaurant,
            imageUrl: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop"
        ),
        ShopPin(
            coordinate: CLLocationCoordinate2D(latitude: 23.1338, longitude: -82.3575),
            type: .supermarket,
            imageUrl: "https://images.unsplash.com/photo-1583258292688-d0213dc5a3a8?w=200&h=200&fit=crop"
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            let width = isMapExpanded ? geometry.size.width : geometry.size.width * 1.5
            let height = isMapExpanded ? geometry.size.height : geometry.size.height * 2.5
            let maxDimension = max(width, height)

            ZStack {
                // Mapa rectangular con máscara radial condicional
                Map(coordinateRegion: $region, annotationItems: shopPins) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        ShopMapPinView(
                            pin: pin,
                            action: {
                                print("\(pin.type.label) seleccionado")
                                resetInactivityTimer()
                            }
                        )
                    }
                }
                .frame(width: width, height: height)
                .opacity(isMapExpanded ? 1.0 : 0.75)
                .mask(
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: isMapExpanded ? [
                                    .init(color: .white, location: 0.0),
                                    .init(color: .white, location: 1.0)
                                ] : [
                                    .init(color: .white.opacity(1.0), location: 0.0),
                                    .init(color: .white.opacity(0.1), location: 0.6),
                                    .init(color: .white.opacity(0.05), location: 0.7),
                                    .init(color: .white.opacity(0.02), location: 0.8),
                                    .init(color: .white.opacity(0.00), location: 0.9),
                                    .init(color: .clear, location: 1.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: maxDimension * 0.6
                            )
                        )
                        .frame(width: width, height: height)
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if isMapExpanded {
                                resetInactivityTimer()
                            }
                        }
                )

                // Overlay transparente para capturar gestos - solo cuando NO expandido
                if !isMapExpanded {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            expandMap()
                        }
                }

                // Indicador central - solo visible cuando NO está expandido
                if !isMapExpanded {
                    ShopMapCenterIndicator(isPulsing: isPulsing)
                        .frame(width: 80, height: 80)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onDisappear {
            inactivityTimer?.invalidate()
        }
    }

    private func expandMap() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMapExpanded = true
            isFullScreen = true
        }
        resetInactivityTimer()
    }

    private func collapseMap() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isMapExpanded = false
            isFullScreen = false
        }
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            collapseMap()
        }
    }
}

struct ShopPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: ShopPinType
    let imageUrl: String
}

enum ShopPinType {
    case restaurant
    case supermarket

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .supermarket: return "cart.fill"
        }
    }

    var color: Color {
        switch self {
        case .restaurant: return Color(red: 255/255, green: 89/255, blue: 94/255)
        case .supermarket: return Color(red: 90/255, green: 132/255, blue: 103/255)
        }
    }

    var label: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .supermarket: return "Supermercado"
        }
    }
}

private struct ShopMapPinView: View {
    let pin: ShopPin
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 0) {
                // Pin head con imagen
                ZStack {
                    // Borde con color
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    pin.type.color,
                                    pin.type.color.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    // Imagen de internet
                    AsyncImage(url: URL(string: pin.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 42, height: 42)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 42, height: 42)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: pin.type.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 42, height: 42)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .shadow(color: pin.type.color.opacity(0.4), radius: 8, x: 0, y: 4)

                // Pin point
                PinTriangle()
                    .fill(pin.type.color)
                    .frame(width: 16, height: 12)
                    .offset(y: -1)

                // Shadow
                Ellipse()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.25),
                                Color.black.opacity(0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 15
                        )
                    )
                    .frame(width: 30, height: 8)
                    .offset(y: 4)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
}

private struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct ShopMapCenterIndicator: View {
    let isPulsing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.llegoPrimary.opacity(0.18))
                .scaleEffect(isPulsing ? 1.2 : 0.9)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary,
                            Color.llegoPrimary.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: isPulsing)
    }
}

// MARK: - Store List Card (Glass Effect)
private struct StoreListCard: View {
    let store: StoreWithCoordinates
    var onTap: (() -> Void)? = nil

    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .tint(.white)
        } else {
            cardContent
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        }
    }

    private var cardContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Logo compacto
            logoSection

            // Contenido principal
            VStack(alignment: .leading, spacing: 4) {
                // Nombre y estado en línea
                HStack(alignment: .center, spacing: 6) {
                    Text(store.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    statusIndicator

                    Spacer(minLength: 4)

                    // Flecha
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.4))
                }

                // Info compacta: dirección + rating + ETA
                HStack(spacing: 8) {
                    if let address = store.address {
                        Text(address)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Rating
                    if let rating = store.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }

                    // ETA
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.llegoAccent)
                        Text("\(store.etaMinutes) min")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var logoSection: some View {
        AsyncImage(url: URL(string: store.logoUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty, .failure:
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            @unknown default:
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        )
    }

    private var statusIndicator: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(Color.green)
                .frame(width: 5, height: 5)
            Text("Abierto")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Full Screen Map View
private struct FullScreenMapView: View {
    @Binding var mapRegion: MKCoordinateRegion
    let stores: [StoreWithCoordinates]
    let onStoreSelected: (StoreWithCoordinates) -> Void

    var body: some View {
        Map(
            coordinateRegion: $mapRegion,
            annotationItems: stores
        ) { store in
            MapAnnotation(coordinate: store.coordinate) {
                Button(action: {
                    onStoreSelected(store)
                }) {
                    VStack(spacing: 0) {
                        // Pin head con logo
                        ZStack {
                            Circle()
                                .fill(Color.llegoPrimary)
                                .frame(width: 50, height: 50)

                            AsyncImage(url: URL(string: store.logoUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 42, height: 42)
                                        .clipShape(Circle())
                                case .empty, .failure:
                                    Image("generic_logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 42, height: 42)
                                        .clipShape(Circle())
                                @unknown default:
                                    Image("generic_logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 42, height: 42)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 8, x: 0, y: 4)

                        // Pin point
                        PinTriangle()
                            .fill(Color.llegoPrimary)
                            .frame(width: 16, height: 12)
                            .offset(y: -1)

                        // Shadow
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.25),
                                        Color.black.opacity(0)
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 15
                                )
                            )
                            .frame(width: 30, height: 8)
                            .offset(y: 4)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    ShopTabLandingView()
}
