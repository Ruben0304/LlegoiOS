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
                        // Selector de categoría
                        categoryPicker
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

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
            .onSubmit(of: .search) {
                // Solo buscar cuando se presiona "Buscar"
                viewModel.search(query: searchText)
            }
            .onChange(of: searchText) { newValue in
                // Limpiar resultados si se borra el texto
                if newValue.isEmpty {
                    viewModel.clearSearch()
                }
            }
            .onChange(of: viewModel.selectedCategory) { _ in
                // Recargar datos iniciales al cambiar categoría
                if searchText.isEmpty {
                    viewModel.loadInitialData()
                } else {
                    viewModel.search(query: searchText)
                }
            }
            .onAppear {
                viewModel.loadInitialData()
            }
            .ignoresSafeArea(.container, edges: .bottom)
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
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        Picker("Categoría", selection: $viewModel.selectedCategory) {
            ForEach(SearchCategory.allCases, id: \.self) { category in
                Text(category.rawValue)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.bottom, 16)
    }
    
    // MARK: - Initial Content (datos sin búsqueda)
    private var initialContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case .products:
                productsGrid
            case .stores:
                storesGrid
            }
        }
    }
    
    // MARK: - Loading Content
    private var loadingContent: some View {
        CircularLoadingIndicator(
            color: gradientManager.currentAccentColor,
            lineWidth: 6,
            size: 60
        )
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Results Content
    private var resultsContent: some View {
        Group {
            switch viewModel.selectedCategory {
            case .products:
                productsGrid
            case .stores:
                storesGrid
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
                NavigationLink(destination: ProductDetailView(productId: product.id)) {
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
                        onProductTap: nil
                    )
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 26))
                .tint(.white)
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
                    onStoreTap: { _ in },
                    onProductTap: { _, _ in },
                    onFavoriteTap: { product in
                        FavoritesManager.shared.toggleFavorite(productId: product.id)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
    }
}
