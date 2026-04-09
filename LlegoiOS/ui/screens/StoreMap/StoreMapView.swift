import MapKit
import SwiftUI

private enum StoreMapDisplayMode: String, CaseIterable {
    case map = "Mapa"
    case list = "Listado"
}

struct StoreMapView: View {
    @StateObject private var viewModel = StoreMapViewModel()
    @StateObject private var listViewModel = StoreListViewModel()
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var selectedStore: StoreWithCoordinates? = nil
    @State private var navigationDestination: StoreMapDestination? = nil
    @State private var pendingDestination: StoreMapDestination? = nil
    @State private var selectedStoreGradient: ExtractedGradient? = nil
    @State private var displayMode: StoreMapDisplayMode = .map

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1345, longitude: -82.3589),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )

    var body: some View {
        NavigationStack {
            Group {
                switch displayMode {
                case .map:
                    mapContent
                        .overlay {
                            if viewModel.isLoading {
                                loadingState
                            }
                        }
                case .list:
                    listContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Lugares")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            withAnimation { displayMode = .map }
                        } label: {
                            Label("Mapa", systemImage: "map")
                        }
                        Button {
                            withAnimation { displayMode = .list }
                        } label: {
                            Label("Listado", systemImage: "list.bullet")
                        }
                    } label: {
                        Text("Ver como")
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }
            }
            .navigationDestination(item: $navigationDestination) { destination in
                switch destination {
                case .detail(let store):
                    StoreDetailView(store: store.toStore())
                case .products(let branchId, let branchName, let gradient):
                    ProductListView(
                        branchId: branchId, branchName: branchName, storeGradient: gradient)
                }
            }
            .sheet(
                item: $selectedStore,
                onDismiss: {
                    if let destination = pendingDestination {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            navigationDestination = destination
                            pendingDestination = nil
                        }
                    }
                }
            ) { store in
                StoreMapOptionsModal(
                    store: store,
                    onViewProfile: {
                        pendingDestination = .detail(store)
                        selectedStore = nil
                    },
                    onViewProducts: {
                        pendingDestination = .products(
                            branchId: store.id,
                            branchName: store.name,
                            gradient: selectedStoreGradient
                        )
                        selectedStore = nil
                    }
                )
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .onAppear {
                viewModel.loadStores()
                listViewModel.loadStores()
                updateMapRegionFromUserLocation()
            }
        }
    }

    // MARK: - Map Content
    private var mapContent: some View {
        Map(position: mapPositionBinding) {
            ForEach(viewModel.stores) { store in
                Annotation("", coordinate: store.coordinate, anchor: .bottom) {
                    Button(action: {
                        selectedStore = store
                    }) {
                        VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(gradientManager.currentAccentColor)
                                .frame(width: 50, height: 50)

                            CachedAsyncImage(
                                url: URL(string: store.logoUrl),
                                cacheKey: "store_map_\(store.id)",
                                content: { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 42, height: 42)
                                        .clipShape(Circle())
                                },
                                placeholder: {
                                    ZStack {
                                        Color.gray.opacity(0.2)
                                        ProgressView()
                                            .progressViewStyle(
                                                CircularProgressViewStyle(tint: .white)
                                            )
                                            .scaleEffect(0.7)
                                    }
                                    .frame(width: 42, height: 42)
                                    .clipShape(Circle())
                                },
                                failure: {
                                    ZStack {
                                        Color.gray.opacity(0.15)
                                        Image(systemName: "storefront")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .frame(width: 42, height: 42)
                                    .clipShape(Circle())
                                }
                            )
                        }
                        .shadow(color: gradientManager.currentAccentColor.opacity(0.4), radius: 8, x: 0, y: 4)

                        PinTriangle()
                            .fill(gradientManager.currentAccentColor)
                            .frame(width: 16, height: 12)
                            .offset(y: -1)

                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .ignoresSafeArea()
    }

    private var listContent: some View {
        Group {
            if listViewModel.isLoading {
                loadingState
            } else if listViewModel.stores.isEmpty {
                ContentUnavailableView(
                    "No hay tiendas disponibles",
                    systemImage: "storefront"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(listViewModel.stores, id: \.id) { store in
                            StoreProductsCard(
                                store: store,
                                products: listViewModel.products(for: store.id),
                                isLoadingProducts: listViewModel.isLoadingProductsFor(
                                    storeId: store.id),
                                onStoreTap: { gradient in
                                    selectedStore = store
                                    selectedStoreGradient = gradient
                                },
                                onProductTap: { _, gradient in
                                    navigationDestination = .products(
                                        branchId: store.id,
                                        branchName: store.name,
                                        gradient: gradient
                                    )
                                },
                                onFavoriteTap: { product in
                                    FavoritesManager.shared.toggleFavorite(productId: product.id)
                                },
                                onBodyTap: {
                                    navigationDestination = .detail(store)
                                }
                            )
                            .onAppear {
                                listViewModel.loadMoreIfNeeded(currentStore: store)
                            }
                        }

                        if listViewModel.isLoadingMore {
                            ProgressView()
                                .tint(gradientManager.currentAccentColor)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(gradientManager.currentAccentColor)
            Text("Cargando tiendas...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers
    private func updateMapRegionFromUserLocation() {
        if let location = UserLocationManager.shared.userLocation {
            mapRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { .region(mapRegion) },
            set: { newPosition in
                _ = newPosition
            }
        )
    }
}

// MARK: - Navigation Destination
enum StoreMapDestination: Identifiable, Hashable {
    case detail(StoreWithCoordinates)
    case products(branchId: String, branchName: String, gradient: ExtractedGradient?)

    var id: String {
        switch self {
        case .detail(let store):
            return "detail-\(store.id)"
        case .products(let branchId, _, _):
            return "products-\(branchId)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StoreMapDestination, rhs: StoreMapDestination) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Store Options Modal
private struct StoreMapOptionsModal: View {
    let store: StoreWithCoordinates
    let onViewProfile: () -> Void
    let onViewProducts: () -> Void

    @State private var isAnimated = false
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header con imagen
            ZStack(alignment: .bottom) {
                Color.clear
                    .frame(height: 180)
                    .overlay(
                        AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .empty:
                                ZStack {
                                    Color.gray.opacity(0.15)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                                }
                            default:
                                Color.gray.opacity(0.15)
                            }
                        }
                    )
                    .clipped()

                CachedAsyncImage(
                    url: URL(string: store.logoUrl),
                    cacheKey: "store_modal_\(store.id)",
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                    },
                    failure: {
                        ZStack {
                            Color.gray.opacity(0.15)
                            Image(systemName: "storefront")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                )
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

            // Info
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

            // Pills
            HStack(spacing: 16) {
                if let rating = store.rating {
                    InfoPill(
                        icon: "star.fill",
                        iconColor: .orange,
                        value: String(format: "%.1f", rating),
                        label: "Rating"
                    )
                }

                InfoPill(
                    icon: "clock.fill",
                    iconColor: .llegoAccent,
                    value: "\(store.etaMinutes)",
                    label: "min"
                )

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

            // Botones
            VStack(spacing: 12) {
                Button(action: onViewProducts) {
                    HStack(spacing: 10) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Ver Productos")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
                .modifier(GlassProminentButtonModifier())
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .tint(gradientManager.currentAccentColor)

                Button(action: onViewProfile) {
                    HStack(spacing: 10) {
                        Image(systemName: "storefront")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ver Perfil de Tienda")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(.secondarySystemBackground))
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

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    StoreMapView()
}
