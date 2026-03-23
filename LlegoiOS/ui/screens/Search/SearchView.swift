//
//  SearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda con soporte offline (SwiftData + NLEmbedding)
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Binding var searchText: String
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var gradientManager = GradientStateManager.shared
    @StateObject private var syncService = OfflineSyncService.shared
    @State private var productCounts: [String: Int] = [:]
    @State private var selectedStore: StoreWithCoordinates? = nil
    @State private var selectedStoreGradient: ExtractedGradient? = nil
    @State private var navigationDestination: NavigationDestination? = nil
    @State private var pendingDestination: NavigationDestination? = nil
    @State private var selectedProductId: String?
    @State private var showSyncSheet: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                searchGradientBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

                ScrollView {
                    VStack(spacing: 0) {
                        // Indicador de sync activo
                        if case .syncing(let phase) = syncService.syncStatus {
                            syncProgressBanner(phase: phase)
                        }

                        // Botones de modo y sincronización
                        inlineActionButtons

                        // Contenido según estado
                        switch viewModel.state {
                        case .idle:
                            if viewModel.isOfflineMode && !syncService.hasLocalData {
                                noLocalDataPrompt
                            } else {
                                initialContent
                            }
                        case .loading:
                            loadingContent
                        case .success:
                            resultsContent
                        case .empty:
                            emptyContent
                        case .error(let message):
                            errorContent(message: message)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    ApolloClientManager.shared.clearDataCache()
                    viewModel.loadInitialData()
                    if !searchText.isEmpty {
                        viewModel.search(query: searchText)
                    }
                }
                .searchable(
                    text: $searchText,
                    prompt: viewModel.isOfflineMode ? "Buscar sin internet..." : "Buscar productos o negocios..."
                )
            }
            .navigationTitle("Buscar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    categoryMenu
                }
            }
            // Online: busca solo al presionar "Buscar"
            .onSubmit(of: .search) {
                viewModel.search(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    viewModel.clearSearch()
                } else if viewModel.isOfflineMode {
                    // Offline: búsqueda en tiempo real con debounce
                    viewModel.searchLive(query: newValue)
                }
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
                if searchText.isEmpty {
                    viewModel.loadInitialData()
                } else {
                    viewModel.search(query: searchText)
                }
            }
            .onAppear {
                viewModel.configure(modelContext: modelContext)
                syncService.configure(modelContext: modelContext)
                viewModel.loadInitialData()
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationDestination(item: $navigationDestination) { destination in
                switch destination {
                case .detail(let store):
                    StoreDetailView(store: store.toStore())
                case .shop(let branchId, let branchName, let storeGradient):
                    ProductListView(branchId: branchId, branchName: branchName, storeGradient: storeGradient)
                case .home:
                    HomeView()
                case .productDetail:
                    HomeView()
                }
            }
            .sheet(item: $selectedStore, onDismiss: {
                if let destination = pendingDestination {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationDestination = destination
                        pendingDestination = nil
                    }
                }
            }) { store in
                StoreOptionsModal(
                    store: store,
                    onViewProfile: {
                        pendingDestination = .detail(store)
                        selectedStore = nil
                    },
                    onViewProducts: {
                        pendingDestination = .shop(
                            branchId: store.id,
                            branchName: store.name,
                            storeGradient: selectedStoreGradient
                        )
                        selectedStore = nil
                    }
                )
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
            }
            .fullScreenCover(item: $selectedProductId) { productId in
                ProductDetailView(productId: productId)
            }
            .sheet(isPresented: $showSyncSheet) {
                SyncSettingsSheet(syncService: syncService) {
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                }
            }
        }
    }

    // MARK: - Inline Search Controls

    private var inlineActionButtons: some View {
        VStack(spacing: 12) {
            // Picker de modo de búsqueda
            Picker("Modo de búsqueda", selection: Binding(
                get: { viewModel.isOfflineMode },
                set: { newValue in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.setOfflineMode(newValue)
                    }
                }
            )) {
                Label("Con internet", systemImage: "wifi").tag(false)
                Label("Sin internet", systemImage: "wifi.slash").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            // Panel de descarga — solo visible en modo sin internet
            if viewModel.isOfflineMode {
                offlineSyncPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isOfflineMode)
    }

    private var offlineSyncPanel: some View {
        VStack(spacing: 1) {
            syncRow(
                icon: "arrow.down.circle",
                title: "Datos y fotos",
                subtitle: "Descarga todo para búsqueda completa sin conexión",
                isLoading: {
                    if case .syncing = syncService.syncStatus { return true }
                    return false
                }()
            ) {
                Task {
                    await syncService.syncDataOnly()
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                    showSyncSheet = true
                }
            }
            .clipShape(
                .rect(topLeadingRadius: 14, bottomLeadingRadius: 0,
                      bottomTrailingRadius: 0, topTrailingRadius: 14)
            )

            Divider()
                .padding(.leading, 52)
                .background(.regularMaterial)

            syncRow(
                icon: "square.and.arrow.down",
                title: "Solo datos",
                subtitle: "Productos y negocios · sin imágenes",
                isLoading: {
                    if case .syncing(let p) = syncService.syncStatus, p != .images { return true }
                    return false
                }()
            ) {
                Task {
                    await syncService.syncDataOnly()
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                }
            }
            .clipShape(.rect(cornerRadius: 0))

            Divider()
                .padding(.leading, 52)
                .background(.regularMaterial)

            syncRow(
                icon: "photo.stack",
                title: "Solo fotos",
                subtitle: "Actualiza las imágenes ya descargadas",
                isLoading: {
                    if case .syncing(.images) = syncService.syncStatus { return true }
                    return false
                }()
            ) {
                showSyncSheet = true
            }
            .clipShape(
                .rect(topLeadingRadius: 0, bottomLeadingRadius: 14,
                      bottomTrailingRadius: 14, topTrailingRadius: 0)
            )
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(gradientManager.currentAccentColor.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .disabled(syncService.syncStatus != .idle)
        .opacity(syncService.syncStatus != .idle ? 0.6 : 1)
    }

    private func syncRow(
        icon: String,
        title: String,
        subtitle: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(gradientManager.currentAccentColor)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(gradientManager.currentAccentColor)
                    }
                }
                .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isLoading ? "Descargando..." : title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Menu

    private var categoryMenu: some View {
        Menu {
            Button {
                withAnimation { viewModel.selectedCategory = .products }
            } label: {
                Label("Productos", systemImage: "bag")
            }
            Button {
                withAnimation { viewModel.selectedCategory = .stores }
            } label: {
                Label("Negocios", systemImage: "storefront")
            }
            Button {
                withAnimation { viewModel.selectedCategory = .both }
            } label: {
                Label("Ambos", systemImage: "square.grid.2x2")
            }
        } label: {
            Text(categoryLabel)
                .foregroundColor(gradientManager.currentAccentColor)
        }
    }



    // MARK: - Sync Progress Banner

    private func syncProgressBanner(phase: SyncPhase) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if phase == .embeddings {
                    // Mostrar barra de progreso para indexación vectorial
                    Image(systemName: "brain")
                        .font(.system(size: 12))
                } else {
                    ProgressView()
                        .scaleEffect(0.75)
                        .tint(.white)
                }
                Text(phase.rawValue)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                if phase == .embeddings {
                    Text("\(Int(syncService.embeddingProgress * 100))%")
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if phase == .embeddings {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Color.white.opacity(0.2)
                        Color.white.opacity(0.85)
                            .frame(width: geo.size.width * syncService.embeddingProgress)
                            .animation(.linear(duration: 0.1), value: syncService.embeddingProgress)
                    }
                }
                .frame(height: 3)
            }
        }
        .background(gradientManager.currentAccentColor.opacity(0.88))
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: syncService.syncStatus)
    }

    // MARK: - No Local Data Prompt

    private var noLocalDataPrompt: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundColor(.orange.opacity(0.7))

            VStack(spacing: 8) {
                Text("Sin datos locales")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Para buscar sin internet descarga los datos mientras tienes conexión.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 10) {
                Button {
                    Task {
                        await syncService.syncDataOnly()
                        viewModel.configure(modelContext: modelContext)
                        viewModel.loadInitialData()
                    }
                } label: {
                    Label("Descargar datos", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(gradientManager.currentAccentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(syncService.syncStatus != .idle)

                Button {
                    showSyncSheet = true
                } label: {
                    Label("Descargar fotos también", systemImage: "photo.badge.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                .disabled(syncService.syncStatus != .idle)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Menu Helpers

    private var categoryLabel: String {
        switch viewModel.selectedCategory {
        case .products: return "Productos"
        case .stores: return "Negocios"
        case .both: return "Ambos"
        }
    }

    // MARK: - Search Gradient Background

    private var searchGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()
        return ZStack {
            palette.veryLight.opacity(0.4)
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.15), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.3), location: 0.4),
                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.95), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Initial Content

    private var initialContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case .products:
                productsGrid
            case .stores:
                storesGrid
            case .both:
                bothEmptyPrompt
            }
        }
    }

    private var bothEmptyPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.4))
            Text(viewModel.isOfflineMode ? "Escribe para buscar en datos locales" : "Busca productos y negocios a la vez")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Loading Content

    private var loadingContent: some View {
        FullLoadingView(color: gradientManager.currentAccentColor)
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case .products: productsGrid
            case .stores: storesGrid
            case .both: bothContent
            }
        }
    }

    // MARK: - Both Content

    private var bothContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.stores.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Negocios")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(viewModel.stores) { store in
                                Button {
                                    selectedStore = store
                                } label: {
                                    SearchStoreCircleCard(store: store)
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 8)
            }

            if !viewModel.products.isEmpty {
                Text("Productos")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                productsGrid
            }
        }
    }

    // MARK: - Products Grid

    private var productsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            alignment: .center,
            spacing: 20
        ) {
            ForEach(viewModel.products) { product in
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
                        productCounts[product.id] = (productCounts[product.id] ?? 0) + 1
                    },
                    onDecrement: {
                        let current = productCounts[product.id] ?? 0
                        if current > 0 { productCounts[product.id] = current - 1 }
                    },
                    onProductTap: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedProductId = product.id
                    }
                )
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedProductId = product.id
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Stores Grid

    private var storesGrid: some View {
        LazyVStack(spacing: 24) {
            ForEach(viewModel.stores, id: \.id) { store in
                StoreProductsCard(
                    store: store,
                    products: viewModel.storeProducts[store.id] ?? [],
                    isLoadingProducts: viewModel.isLoadingProductsFor(storeId: store.id),
                    onStoreTap: { gradient in
                        selectedStore = store
                        selectedStoreGradient = gradient
                    },
                    onProductTap: { _, gradient in
                        navigationDestination = .shop(
                            branchId: store.id,
                            branchName: store.name,
                            storeGradient: gradient
                        )
                    },
                    onFavoriteTap: { product in
                        FavoritesManager.shared.toggleFavorite(productId: product.id)
                    },
                    onBodyTap: {
                        navigationDestination = .detail(store)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Empty Content

    private var emptyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No se encontraron resultados")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Text(viewModel.isOfflineMode
                 ? "Intenta con otra búsqueda o descarga más datos"
                 : "Intenta con otra búsqueda")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Error Content

    private func errorContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.orange.opacity(0.7))

            Text("Error al buscar")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button("Reintentar") {
                viewModel.search(query: searchText)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

// MARK: - Search Store Circle Card

private struct SearchStoreCircleCard: View {
    let store: StoreWithCoordinates
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cardBackground(colorScheme))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4)

                if !store.logoUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: store.logoUrl),
                        cacheKey: "search_store_\(store.id)",
                        content: { image in image.resizable().scaledToFill() },
                        placeholder: { Circle().fill(Color.gray.opacity(0.2)) },
                        failure: {
                            Image(systemName: "storefront")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                        }
                    )
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "storefront")
                        .font(.system(size: 28))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            }

            Text(store.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80, height: 30, alignment: .top)
        }
    }
}

// MARK: - Sync Settings Sheet

struct SyncSettingsSheet: View {
    @ObservedObject var syncService: OfflineSyncService
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuality: OfflineImageQuality = .baja
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos locales") {
                    HStack {
                        Label("Negocios", systemImage: "storefront")
                        Spacer()
                        Text("\(syncService.businessCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Productos", systemImage: "bag")
                        Spacer()
                        Text("\(syncService.productCount)")
                            .foregroundColor(.secondary)
                    }
                    if let date = syncService.lastSyncDate {
                        HStack {
                            Label("Última actualización", systemImage: "clock")
                            Spacer()
                            Text(date.formatted(.relative(presentation: .named)))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }

                Section("Calidad de fotos") {
                    Picker("Calidad", selection: $selectedQuality) {
                        ForEach(OfflineImageQuality.allCases, id: \.self) { q in
                            Text(q.displayName).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedQuality == .baja
                         ? "Miniaturas 100×100 — ocupa poco espacio"
                         : "Calidad original — mayor detalle, más espacio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progreso si se está indexando
                if case .syncing(let phase) = syncService.syncStatus {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                if phase == .embeddings {
                                    Image(systemName: "brain")
                                        .foregroundColor(gradientManager.currentAccentColor)
                                } else {
                                    ProgressView().scaleEffect(0.85)
                                }
                                Text(phase.rawValue)
                                    .font(.system(size: 14))
                                Spacer()
                                if phase == .embeddings {
                                    Text("\(Int(syncService.embeddingProgress * 100))%")
                                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }
                            }
                            if phase == .embeddings {
                                ProgressView(value: syncService.embeddingProgress)
                                    .tint(gradientManager.currentAccentColor)
                            }
                        }
                    }
                }

                if case .failed(let msg) = syncService.syncStatus {
                    Section {
                        Label(msg, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task {
                            await syncService.syncImagesOnly(quality: selectedQuality)
                            onDone()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Label("Actualizar fotos", systemImage: "photo.stack")
                            Spacer()
                            if case .syncing(.images) = syncService.syncStatus {
                                ProgressView().scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(syncService.syncStatus != .idle)
                }
            }
            .navigationTitle("Fotos sin internet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
    }
}
