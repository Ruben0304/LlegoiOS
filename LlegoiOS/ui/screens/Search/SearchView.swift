//
//  SearchView.swift
//  LlegoiOS
//
//  Pantalla de búsqueda con Tab(role: .search)
//  Usa los mismos componentes que ProductListView y StoreListView
//

import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var productCounts: [String: Int] = [:]
    @State private var selectedStore: StoreWithCoordinates? = nil
    @State private var selectedStoreGradient: ExtractedGradient? = nil
    @State private var navigationDestination: NavigationDestination? = nil
    @State private var pendingDestination: NavigationDestination? = nil
    @State private var selectedProductId: String?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gradiente sutil sincronizado
                searchGradientBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

                ScrollView {
                    VStack(spacing: 0) {
                        // Contenido según estado y categoría
                        switch viewModel.state {
                        case .idle:
                            // Mostrar datos iniciales
                            initialContent
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
                .searchable(
                    text: $searchText,
                    prompt: "Buscar productos o negocios..."
                )
            }
            .navigationTitle("Buscar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                            .foregroundColor(.llegoPrimary)
                    }
                }
            }
            .onSubmit(of: .search) {
                // Solo buscar cuando se presiona "Buscar"
                print("🔍 SearchView - onSubmit triggered with query: '\(searchText)'")
                viewModel.search(query: searchText)
            }
            .onChange(of: searchText) { _, newValue in
                print("🔍 SearchView - searchText changed to: '\(newValue)'")
                // Limpiar resultados si se borra el texto
                if newValue.isEmpty {
                    print("🔍 SearchView - searchText is empty, clearing search")
                    viewModel.clearSearch()
                }
            }
            .onChange(of: viewModel.selectedCategory) { _, newCategory in
                print("🔍 SearchView - selectedCategory changed to: \(newCategory)")
                // Recargar datos iniciales al cambiar categoría
                if searchText.isEmpty {
                    print("🔍 SearchView - searchText is empty, loading initial data")
                    viewModel.loadInitialData()
                } else {
                    print("🔍 SearchView - searchText is not empty, searching with: '\(searchText)'")
                    viewModel.search(query: searchText)
                }
            }
            .onAppear {
                print("🔍 SearchView - onAppear, loading initial data")
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
                case .productDetail(productId: let productId):
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
        }

    }

    // MARK: - Category Menu Helpers
    private var categoryLabel: String {
        switch viewModel.selectedCategory {
        case .products: return "Productos"
        case .stores: return "Negocios"
        case .both: return "Ambos"
        }
    }

    private var categoryIcon: String {
        switch viewModel.selectedCategory {
        case .products: return "bag.fill"
        case .stores: return "storefront.fill"
        case .both: return "square.grid.2x2.fill"
        }
    }

    // MARK: - Search Gradient Background
    private var searchGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.4)

            // Gradiente sutil
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

    // MARK: - Initial Content (datos sin búsqueda)
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
            Text("Busca productos y negocios a la vez")
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
            case .products:
                productsGrid
            case .stores:
                storesGrid
            case .both:
                bothContent
            }
        }
    }

    // MARK: - Both Content (negocios circular arriba + productos abajo)
    private var bothContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Negocios – scroll horizontal circular
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

            // Productos – grid vertical
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

    // MARK: - Products Grid (igual que ProductListView)
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
                        if current > 0 {
                            productCounts[product.id] = current - 1
                        }
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

    // MARK: - Stores Grid (igual que StoreListView con StoreProductsCard)
    private var storesGrid: some View {
        LazyVStack(spacing: 24) {
            ForEach(viewModel.stores) { store in
                StoreProductsCard(
                    store: store,
                    products: viewModel.storeProducts[store.id] ?? [],
                    isLoadingProducts: viewModel.isLoadingProductsFor(storeId: store.id),
                    onStoreTap: { gradient in
                        selectedStore = store
                        selectedStoreGradient = gradient
                    },
                    onProductTap: { product, gradient in
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

            Text("Intenta con otra búsqueda")
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
                        content: { image in
                            image.resizable().scaledToFill()
                        },
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
                        .foregroundColor(.llegoPrimary)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
    }
}
