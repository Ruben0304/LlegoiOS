import SwiftUI
import MapKit

struct ShopTabLandingView: View {
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchExpanded = false
    @State private var isMapFullScreen = false
    @State private var isSearchLoading: Bool = false
    @State private var showSearchResults: Bool = false
    @State private var searchResultsOffset: CGFloat = -50
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    // Resultados filtrados de búsqueda (solo vendedores)
    @State private var filteredSearchStores: [StoreWithCoordinates] = []

    // Selección de vendedor
    @State private var selectedStore: StoreWithCoordinates? = nil
    @State private var showStoreOptionsModal: Bool = false

    // Navegación
    @State private var navigateToStoreDetail: Bool = false
    @State private var navigateToHome: Bool = false

    // Instagram Stories Viewer
    @State private var showStoryViewer: Bool = false
    @State private var storyData: [StoryData] = []
    @State private var currentStoryIndex: Int = 0

    // Región del mapa compartida
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1345, longitude: -82.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                // HISTORIAS Y MAPA (no superpuestos)
                if !isMapFullScreen {
                    VStack(spacing: 0) {
                        // Stories Section (Instagram-style) - Arriba
                        if !storyData.isEmpty {
                            StoreStories(
                                storyData: storyData,
                                onStoryTap: { store in
                                    // Abrir Instagram Story Viewer a pantalla completa
                                    if let index = storyData.firstIndex(where: { $0.store.id == store.id }) {
                                        currentStoryIndex = index
                                        showStoryViewer = true
                                    }
                                }
                            )
                            .background(Color.llegoBackground)
                            .zIndex(1)
                        }

                        // Spacer para separar historias del mapa
                        Spacer()
                            .frame(height: 16)

                        // Mapa justo debajo de las historias (sin superposición)
                        RadialShopMapView(
                                isFullScreen: $isMapFullScreen
                        )
                        .frame(height: 360)
                        .clipped()
                        .zIndex(0)

                        Spacer()
                    }
                } else {
                    // Mapa en pantalla completa
                    RadialShopMapView(
                        isFullScreen: $isMapFullScreen
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }

                // Card de búsqueda como overlay flotante
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
                }

                // Modal de opciones de tienda
                if showStoreOptionsModal, let store = selectedStore {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showStoreOptionsModal = false
                            }
                        }

                    StoreOptionsModal(
                        store: store,
                        onViewProfile: {
                            showStoreOptionsModal = false
                            navigateToStoreDetail = true
                        },
                        onViewProducts: {
                            showStoreOptionsModal = false
                            navigateToHome = true
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showStoreOptionsModal = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    searchToolbar
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
            .fullScreenCover(isPresented: $navigateToStoreDetail) {
                if let store = selectedStore {
//                    StoreDetailView(store: store)
                }
            }
            .fullScreenCover(isPresented: $navigateToHome) {
                if let store = selectedStore {
                    HomeView()
                }
            }
            .fullScreenCover(isPresented: $showStoryViewer) {
                InstagramStoryViewer(
                    stories: $storyData,
                    currentStoryIndex: $currentStoryIndex,
                    isPresented: $showStoryViewer
                )
            }
            .onAppear {
                // Inicializar historias mock
                initializeMockStories()
            }
        }
    }

    // MARK: - Initialize Mock Stories
    private func initializeMockStories() {
        storyData = mockStores.map { storeWithCoords in
            let store = storeWithCoords.toStore()

            // Crear múltiples items de historia por tienda (2-3 historias)
            let storyItems: [StoryItem] = [
                StoryItem(
                    mediaUrl: storeWithCoords.bannerUrl,
                    mediaType: .image,
                    duration: 5.0,
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                StoryItem(
                    mediaUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=1080&h=1920&fit=crop",
                    mediaType: .image,
                    duration: 5.0,
                    timestamp: Date().addingTimeInterval(-1800)
                ),
                StoryItem(
                    mediaUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=1080&h=1920&fit=crop",
                    mediaType: .image,
                    duration: 5.0,
                    timestamp: Date().addingTimeInterval(-900)
                )
            ]

            return StoryData(
                id: store.id,
                store: store,
                items: storyItems
            )
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

        // Simular búsqueda de 1 segundo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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

    // MARK: - Animar mapa a ubicación de tienda
    private func animateToStore(_ store: StoreWithCoordinates) {
        // Cerrar búsqueda
        isSearchFocused = false
        searchText = ""
        isSearchExpanded = false
        showSearchResults = false

        // Animar mapa a la ubicación con animación fluida y lenta
        withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
            mapRegion = MKCoordinateRegion(
                center: store.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        }

        // Mostrar modal después de la animación
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showStoreOptionsModal = true
            }
        }
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

    // MARK: - Mock Data
    private let mockStores = [
        StoreWithCoordinates(
            id: "1",
            name: "FreshMart Premium",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
            address: "Calle 23 #456, Vedado",
            rating: 4.8,
            coordinate: CLLocationCoordinate2D(latitude: 23.1355, longitude: -82.3600)
        ),
        StoreWithCoordinates(
            id: "2",
            name: "EcoFruit Orgánico",
            etaMinutes: 30,
            logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
            address: "Av. 5ta #789, Miramar",
            rating: 4.6,
            coordinate: CLLocationCoordinate2D(latitude: 23.1338, longitude: -82.3575)
        ),
        StoreWithCoordinates(
            id: "3",
            name: "TropicalFresh Market",
            etaMinutes: 20,
            logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
            address: "Calle 10 #234, Plaza",
            rating: 4.9,
            coordinate: CLLocationCoordinate2D(latitude: 23.1348, longitude: -82.3595)
        ),
        StoreWithCoordinates(
            id: "4",
            name: "La Bodeguita del Sabor",
            etaMinutes: 15,
            logoUrl: "https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&h=200&fit=crop&crop=center",
            address: "Calle L #567, Vedado",
            rating: 4.7,
            coordinate: CLLocationCoordinate2D(latitude: 23.1340, longitude: -82.3610)
        ),
        StoreWithCoordinates(
            id: "5",
            name: "SuperMercado El Rápido",
            etaMinutes: 18,
            logoUrl: "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&h=200&fit=crop&crop=center",
            address: "Av. 31 #890, Nuevo Vedado",
            rating: 4.5,
            coordinate: CLLocationCoordinate2D(latitude: 23.1352, longitude: -82.3580)
        )
    ]
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

// MARK: - StoreOptionsModal
private struct StoreOptionsModal: View {
    let store: StoreWithCoordinates
    let onViewProfile: () -> Void
    let onViewProducts: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Indicador de arrastre
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                // Información de la tienda
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: store.logoUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty, .failure:
                            Color.gray.opacity(0.3)
                        @unknown default:
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.llegoSecondary.opacity(0.3), lineWidth: 2)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.llegoPrimary)

                        if let address = store.address {
                            Text(address)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if let rating = store.rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)

                // Botones de acción
                VStack(spacing: 12) {
                    Button(action: onViewProfile) {
                        HStack {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Ver Perfil de Tienda")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.llegoPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }

                    Button(action: onViewProducts) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Ver Productos")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.llegoAccent)
                        .foregroundColor(.llegoPrimary)
                        .cornerRadius(14)
                    }

                    Button(action: onDismiss) {
                        Text("Cancelar")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -5)
            )
        }
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

#Preview {
    ShopTabLandingView()
}
