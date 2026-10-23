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
    @State private var showCombinationAlert = false
    @State private var combinationAlertTitle = ""
    @State private var combinationAlertMessage = ""
    @State private var configurationCombination: SearchCombination?
    @State private var didAddConfiguredCombination = false
    @State private var isPreparingCombination = false
    @State private var combinationPreparationTask: Task<Void, Never>?
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

                        // Aviso de fallback automático a búsqueda offline
                        if viewModel.isShowingOfflineFallback {
                            offlineFallbackBanner
                        }
                        if let notice = viewModel.combinationNotice {
                            combinationNoticeBanner(notice)
                        }

                        // Contenido según estado
                        switch viewModel.state {
                        case .idle:
                            initialContent
                        case .loading:
                            loadingContent
                        case .success:
                            resultsContent
                        case .empty:
                            if !viewModel.cartSearchSuggestions.isEmpty || !viewModel.cartAlternativeCombinations.isEmpty || viewModel.isLoadingCartSuggestions {
                                resultsContent
                            } else if viewModel.isShowingCombinationResults {
                                combinationResultsContent
                            } else {
                                emptyContent
                            }
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
                    prompt: viewModel.isShowingOfflineFallback ? "Buscar sin internet..." : "Buscar productos o negocios..."
                )
                .sheet(item: $configurationCombination, onDismiss: {
                    if didAddConfiguredCombination {
                        didAddConfiguredCombination = false
                        combinationAlertTitle = "Añadido al carrito"
                        combinationAlertMessage = "Productos añadidos al carrito"
                        showCombinationAlert = true
                    }
                }) { combination in
                    SearchCombinationConfigurationSheet(combination: combination) {
                        didAddConfiguredCombination = true
                    }
                }
            }
            .navigationTitle("Buscar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    downloadMenu
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    categoryMenu
                }
            }
            // Siempre intenta por internet primero al presionar "Buscar"
            .onSubmit(of: .search) {
                viewModel.search(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    viewModel.clearSearch()
                } else if viewModel.isShowingOfflineFallback {
                    // Ya estamos sirviendo datos locales: búsqueda en tiempo real con debounce
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
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.loadInitialData()
                } else {
                    viewModel.search(query: searchText)
                }
            }
            .onDisappear {
                combinationPreparationTask?.cancel()
                combinationPreparationTask = nil
                isPreparingCombination = false
                viewModel.cancelCurrentSearch()
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
            .alert(combinationAlertTitle, isPresented: $showCombinationAlert) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(combinationAlertMessage)
            }
            .sheet(isPresented: $showSyncSheet) {
                SyncSettingsSheet(syncService: syncService) {
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                }
            }
        }
        .disabled(isPreparingCombination)
        .overlay {
            if isPreparingCombination {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Preparando combinación…")
                            .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Download Menu (toolbar)

    private var downloadMenu: some View {
        Menu {
            Button {
                Task {
                    await syncService.syncDataOnly()
                    await syncService.syncImagesOnly(quality: .baja)
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                }
            } label: {
                Label("Datos y fotos", systemImage: "arrow.down.circle")
            }

            Button {
                Task {
                    await syncService.syncDataOnly()
                    viewModel.configure(modelContext: modelContext)
                    viewModel.loadInitialData()
                }
            } label: {
                Label("Solo datos", systemImage: "square.and.arrow.down")
            }

            Button {
                showSyncSheet = true
            } label: {
                Label("Solo fotos", systemImage: "photo.stack")
            }
        } label: {
            if case .syncing = syncService.syncStatus {
                Label("Descargando...", systemImage: "arrow.down.circle")
            } else {
                Label("Descargar datos", systemImage: "arrow.down.circle")
            }
        }
        .labelStyle(.titleAndIcon)
        .disabled(syncService.syncStatus != .idle)
    }

    // MARK: - Offline Fallback Banner

    private var offlineFallbackBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
            Text("Buscando sin internet")
                .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
            Spacer()
            Button {
                if searchText.isEmpty {
                    viewModel.loadInitialData()
                } else {
                    viewModel.search(query: searchText)
                }
            } label: {
                Text("Probar con internet")
                    .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.25), in: Capsule())
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(gradientManager.currentAccentColor.opacity(0.88))
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.isShowingOfflineFallback)
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
                        .scaledFont(size: 12, relativeTo: .caption)
                } else {
                    ProgressView()
                        .scaleEffect(0.75)
                        .tint(.white)
                }
                Text(phase.rawValue)
                    .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                Spacer()
                if phase == .embeddings {
                    Text("\(Int(syncService.embeddingProgress * 100))%")
                        .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                        .monospacedDigit()
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
                .scaledFont(size: 40, weight: .ultraLight, relativeTo: .largeTitle)
                .foregroundColor(.secondary.opacity(0.4))
            Text(viewModel.isShowingOfflineFallback ? "Escribe para buscar en datos locales" : "Busca productos y negocios a la vez")
                .scaledFont(size: 16, weight: .medium, relativeTo: .body)
                .foregroundColor(.secondary)
            if !viewModel.isShowingOfflineFallback {
                Text("Prueba: pizza de piña y helado de chocolate")
                    .scaledFont(size: 14, relativeTo: .subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
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
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isLoadingCartSuggestions {
                ProgressView("Buscando opciones para tu carrito…")
                    .font(.footnote)
                    .tint(Color.llegoPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
            if let context = viewModel.cartSearchContext, !viewModel.cartSearchSuggestions.isEmpty {
                SearchCartSuggestionsView(context: context, suggestions: viewModel.cartSearchSuggestions) { productId in
                    selectedProductId = productId
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            if !viewModel.cartAlternativeCombinations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tu combinación en otros negocios")
                        .font(.headline)
                    Text("Lo que tienes en el carrito junto con lo que buscas, disponible en una misma sucursal. Toca un producto para ver sus opciones.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.cartAlternativeCombinations) { combination in
                        SearchCombinationCard(
                            combination: combination, isPreparing: false,
                            onAdd: {}, onProductTap: { selectedProductId = $0 })
                    }
                }
                .padding(.horizontal, 20)
            }
            if viewModel.isShowingCombinationResults {
                combinationResultsContent
            } else {
                switch viewModel.selectedCategory {
                case .products:
                    if !viewModel.cartSearchSuggestions.isEmpty, !regularProducts.isEmpty {
                        Text("Más opciones")
                            .font(.headline)
                            .padding(.horizontal, 20)
                    }
                    productsGrid
                case .stores: storesGrid
                case .both: bothContent
                }
            }
        }
    }

    private var combinationResultsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.searchCombinations.isEmpty {
                Text("Combinaciones en la misma sucursal")
                    .scaledFont(size: 19, weight: .bold, design: .rounded, relativeTo: .title3)
                    .padding(.horizontal, 20)
                ForEach(viewModel.searchCombinations) { combination in
                    SearchCombinationCard(combination: combination, isPreparing: isPreparingCombination) {
                        addCombination(combination)
                    }
                    .padding(.horizontal, 20)
                }
            }

            if !viewModel.combinationIntentResults.isEmpty {
                Text(viewModel.searchCombinations.isEmpty ? "Productos por separado" : "Más opciones por producto")
                    .scaledFont(size: 19, weight: .bold, design: .rounded, relativeTo: .title3)
                    .padding(.horizontal, 20)
                ForEach(Array(viewModel.combinationIntentResults.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.intent.capitalized)
                            .scaledFont(size: 16, weight: .semibold, relativeTo: .body)
                            .padding(.horizontal, 20)
                        if group.products.isEmpty {
                            Text("No encontramos productos para «\(group.intent)».")
                                .scaledFont(size: 14, relativeTo: .subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(group.products, id: \.id) { product in
                                SearchCombinationSuggestionRow(product: product) {
                                    selectedProductId = product.id
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }

            if viewModel.searchCombinations.isEmpty && viewModel.combinationIntentResults.isEmpty {
                Text("No encontramos productos disponibles para todos los pedidos.")
                    .scaledFont(size: 15, relativeTo: .subheadline)
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
        }
        .padding(.top, 14)
    }

    private func addCombination(_ combination: SearchCombination) {
        guard !isPreparingCombination else { return }
        isPreparingCombination = true
        combinationPreparationTask = Task { @MainActor in
            defer {
                isPreparingCombination = false
                combinationPreparationTask = nil
            }
            do {
                switch try await SearchCombinationCartCoordinator.shared.prepare(combination) {
                case .added:
                    combinationAlertTitle = "Añadido al carrito"
                    combinationAlertMessage = "Productos añadidos al carrito"
                    showCombinationAlert = true
                case .requiresConfiguration:
                    configurationCombination = combination
                }
            } catch is CancellationError {
                return
            } catch {
                combinationAlertTitle = "No se pudo preparar la combinación"
                combinationAlertMessage = error.localizedDescription
                showCombinationAlert = true
            }
        }
    }

    private func combinationNoticeBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
            Text(message)
                .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.llegoPrimary)
        .padding(12)
        .background(Color.llegoAccent.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Both Content

    private var bothContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.stores.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Negocios")
                        .scaledFont(size: 18, weight: .bold, design: .rounded, relativeTo: .title3)
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

            if !regularProducts.isEmpty {
                Text(viewModel.cartSearchSuggestions.isEmpty ? "Productos" : "Más opciones")
                    .scaledFont(size: 18, weight: .bold, design: .rounded, relativeTo: .title3)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                productsGrid
            }
        }
    }

    // MARK: - Products Grid

    private var regularProducts: [Product] {
        let highlightedIds = Set(viewModel.cartSearchSuggestions.map(\.id))
        return viewModel.products.filter { !highlightedIds.contains($0.id) }
    }

    private var productsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            alignment: .center,
            spacing: 20
        ) {
            ForEach(regularProducts) { product in
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
                .scaledFont(size: 48, weight: .ultraLight, relativeTo: .largeTitle)
                .foregroundColor(.secondary.opacity(0.5))

            Text("No se encontraron resultados")
                .scaledFont(size: 18, weight: .medium, relativeTo: .title3)
                .foregroundColor(.secondary)

            Text(viewModel.isShowingOfflineFallback
                 ? "Intenta con otra búsqueda o descarga más datos"
                 : "Intenta con otra búsqueda")
                .scaledFont(size: 14, relativeTo: .subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Error Content

    private func errorContent(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .scaledFont(size: 48, weight: .ultraLight, relativeTo: .largeTitle)
                .foregroundColor(.orange.opacity(0.7))

            Text("Error al buscar")
                .scaledFont(size: 18, weight: .medium, relativeTo: .title3)
                .foregroundColor(.secondary)

            Text(message)
                .scaledFont(size: 14, relativeTo: .subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Button("Reintentar") {
                viewModel.search(query: searchText)
            }
            .scaledFont(size: 16, weight: .medium, relativeTo: .body)
            .foregroundColor(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }
}

private struct SearchCombinationCard: View {
    let combination: SearchCombination
    let isPreparing: Bool
    let onAdd: () -> Void
    var onProductTap: ((String) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "storefront")
                Text(combination.branchName)
                    .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                Spacer()
                Text("Misma sucursal")
                    .scaledFont(size: 11, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(combination.products) { product in
                if let onProductTap {
                    Button { onProductTap(product.id) } label: {
                        productRow(product)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Ver opciones del producto")
                } else {
                    productRow(product)
                }
            }

            HStack {
                Text("Total de productos")
                    .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                Spacer()
                Text(String(format: "%.2f %@", combination.totalPrice, combination.currency))
                    .scaledFont(size: 16, weight: .bold, relativeTo: .body)
            }

            Text("Las opciones, el envío y los cargos pueden cambiar el total.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if onProductTap == nil {
                Button(action: onAdd) {
                    HStack(spacing: 8) {
                        if isPreparing { ProgressView().tint(.white) }
                        Text(isPreparing ? "Preparando…" : (combination.products.count == 2 ? "Añadir ambos" : "Añadir combinación"))
                            .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.llegoPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isPreparing)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func productRow(_ product: SearchCombinationProduct) -> some View {
        HStack(spacing: 12) {
            combinationImage(product.imageUrl)
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .scaledFont(size: 14, weight: .medium, relativeTo: .subheadline)
                    .lineLimit(2)
                Text(String(format: "%.2f %@", product.price, product.currency))
                    .scaledFont(size: 13, weight: .semibold, relativeTo: .footnote)
                    .foregroundStyle(Color.llegoPrimary)
            }
            Spacer(minLength: 0)
            if onProductTap != nil {
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func combinationImage(_ url: String?) -> some View {
        if let url, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    imagePlaceholder
                }
            }
            .frame(width: 58, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.12))
            .frame(width: 58, height: 52)
            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
    }
}

private struct SearchCombinationSuggestionRow: View {
    let product: SearchCombinationCandidate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let url = product.imageUrl, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image { image.resizable().scaledToFill() }
                        else { suggestionPlaceholder }
                    }
                    .frame(width: 56, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                } else {
                    suggestionPlaceholder
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .scaledFont(size: 14, weight: .medium, relativeTo: .subheadline)
                        .lineLimit(2)
                    Text("Negocio: \(product.businessName) · \(String(format: "%.2f %@", product.price, product.currency))")
                        .scaledFont(size: 12, relativeTo: .caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .scaledFont(size: 11, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var suggestionPlaceholder: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(Color.gray.opacity(0.12))
            .frame(width: 56, height: 48)
            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
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
                                .scaledFont(size: 28, relativeTo: .title)
                                .foregroundColor(.gray)
                        }
                    )
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "storefront")
                        .scaledFont(size: 28, relativeTo: .title)
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            }

            Text(store.name)
                .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
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
                                    .scaledFont(size: 14, relativeTo: .subheadline)
                                Spacer()
                                if phase == .embeddings {
                                    Text("\(Int(syncService.embeddingProgress * 100))%")
                                        .scaledFont(size: 13, weight: .semibold, relativeTo: .footnote)
                                        .monospacedDigit()
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
                        let quality = selectedQuality
                        dismiss()
                        Task {
                            await syncService.syncImagesOnly(quality: quality)
                            onDone()
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
