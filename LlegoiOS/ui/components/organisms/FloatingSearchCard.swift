//
//  FloatingSearchCard.swift
//  LlegoiOS
//
//  Card de búsqueda flotante reutilizable
//  Igual al que aparece en HomeView
//

import SwiftUI

enum FloatingSearchType {
    case products
    case stores

    var placeholder: String {
        switch self {
        case .products: return "Buscar productos..."
        case .stores: return "Buscar vendedores..."
        }
    }
}

struct FloatingSearchCard: View {
    let type: FloatingSearchType
    @Binding var selectedValue: String?
    @Binding var isVisible: Bool
    var showNothingElseOption: Bool = false // Opción "más nada"

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSearchLoading: Bool = false
    @State private var showSearchResults: Bool = false
    @State private var searchResultsOffset: CGFloat = -50
    @State private var searchDebounceTask: Task<Void, Never>? = nil

    // Resultados filtrados
    @State private var filteredCategories: [(String, String)] = []
    @State private var filteredSearchProducts: [Product] = []
    @State private var filteredSearchStores: [Store] = []

    var body: some View {
        VStack(spacing: 0) {
            // Barra de búsqueda integrada en el card
            searchBarView
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            // Contenido del card
            if isSearchLoading {
                // Skeleton loading
                searchSkeletonContent
            } else if showSearchResults {
                // Resultados de búsqueda
                searchResultsView
                    .offset(y: searchResultsOffset)
                    .opacity(showSearchResults ? 1 : 0)
            } else {
                // Datos predefinidos iniciales
                initialDataView
            }
        }
        .background(Color.clear)
        .cornerRadius(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .onAppear {
            loadInitialData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
        .onChange(of: searchText) { newValue in
            handleSearchChange(newValue)
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))

            TextField(type.placeholder, text: $searchText)
                .font(.system(size: 17))
                .autocorrectionDisabled()
                .focused($isSearchFocused)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button(action: {
                isSearchFocused = false
                searchText = ""
                isVisible = false
            }) {
                Text("Cancelar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.llegoSurface.opacity(0.8))
        )
    }

    // MARK: - Initial Data View
    private var initialDataView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if type == .products {
                    // Mostrar categorías + productos
                    if !filteredCategories.isEmpty {
                        categoriesSection
                    }

                    if !filteredCategories.isEmpty && !filteredSearchProducts.isEmpty {
                        Divider()
                            .padding(.horizontal, 12)
                    }

                    if !filteredSearchProducts.isEmpty {
                        productsSection
                    }
                } else {
                    // Mostrar solo vendedores
                    if !filteredSearchStores.isEmpty {
                        sellersSection
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 500)
    }

    // MARK: - Search Results View
    private var searchResultsView: some View {
        let hasCategories = !filteredCategories.isEmpty
        let hasProducts = !filteredSearchProducts.isEmpty
        let hasStores = !filteredSearchStores.isEmpty
        let hasAnyResults = hasCategories || hasProducts || hasStores

        return ScrollView {
            Group {
                if hasAnyResults {
                    VStack(spacing: 20) {
                        // Categorías (solo para productos)
                        if type == .products && hasCategories {
                            categoriesSection
                        }

                        if type == .products && hasCategories && hasProducts {
                            Divider()
                                .padding(.horizontal, 12)
                        }

                        // Productos (solo para búsqueda de productos)
                        if type == .products && hasProducts {
                            productsSection
                        }

                        // Vendedores (solo para búsqueda de vendedores)
                        if type == .stores && hasStores {
                            sellersSection
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 4)
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
                }
            }
        }
        .frame(maxHeight: 500)
    }

    // MARK: - Skeleton Loading
    private var searchSkeletonContent: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.llegoPrimary.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .shimmer()

                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoPrimary.opacity(0.2))
                            .frame(height: 12)
                            .shimmer()

                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.llegoPrimary.opacity(0.2))
                            .frame(height: 10)
                            .frame(maxWidth: 140)
                            .shimmer()

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
    }

    // MARK: - Sections
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
                        .onTapGesture {
                            selectValue(category.0)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private var productsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Productos")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                // Opción "más nada" como primera opción
                if showNothingElseOption {
                    Button(action: {
                        selectValue("más nada")
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.llegoSecondary.opacity(0.2))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.llegoSecondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Más nada")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("No agregar más productos")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.llegoSecondary.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Productos normales
                ForEach(filteredSearchProducts, id: \.id) { product in
                    ProductListItem(product: product, compact: true)
                        .onTapGesture {
                            selectValue(product.name)
                        }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private var sellersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vendedores")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .padding(.horizontal, 12)

            VStack(spacing: 8) {
                ForEach(filteredSearchStores, id: \.id) { store in
                    SellerListItem(store: store, compact: true)
                        .onTapGesture {
                            selectValue(store.name)
                        }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Actions
    private func selectValue(_ value: String) {
        selectedValue = value
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }
    }

    // MARK: - Data Loading
    private func loadInitialData() {
        if type == .products {
            filteredCategories = mockCategories
            filteredSearchProducts = mockProducts
        } else {
            filteredSearchStores = mockStores
        }
    }

    private func handleSearchChange(_ newValue: String) {
        searchDebounceTask?.cancel()

        if !newValue.isEmpty {
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    performSearch()
                }
            }
        } else {
            isSearchLoading = false
            showSearchResults = false
            loadInitialData()
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            loadInitialData()
            showSearchResults = false
            return
        }

        isSearchLoading = true
        showSearchResults = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if type == .products {
                filteredCategories = mockCategories.filter { category in
                    category.0.localizedCaseInsensitiveContains(searchText)
                }

                filteredSearchProducts = mockProducts.filter { product in
                    product.name.localizedCaseInsensitiveContains(searchText) ||
                    product.shop.localizedCaseInsensitiveContains(searchText)
                }.prefix(10).map { $0 }
            } else {
                filteredSearchStores = mockStores.filter { store in
                    store.name.localizedCaseInsensitiveContains(searchText) ||
                    (store.address?.localizedCaseInsensitiveContains(searchText) ?? false)
                }.prefix(10).map { $0 }
            }

            isSearchLoading = false
            showSearchResults = true

            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                searchResultsOffset = 0
            }
        }
    }

    // MARK: - Mock Data
    private let mockCategories = [
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
        ),
        Product(
            id: "4",
            name: "Tomate fresco",
            shop: "FreshMart",
            weight: "500g",
            price: "$1.75",
            imageUrl: "https://images.unsplash.com/photo-1546470427-e26264be0b6e?w=400"
        ),
        Product(
            id: "5",
            name: "Lechuga romana",
            shop: "EcoFruit",
            weight: "250g",
            price: "$1.25",
            imageUrl: "https://images.unsplash.com/photo-1556801712-76c8eb07bbc9?w=400"
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
        ),
        Store(
            id: "4",
            name: "La Bodeguita del Medio",
            etaMinutes: 15,
            logoUrl: "https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&h=200&fit=crop&crop=center",
            address: "Calle Obispo #207, Habana Vieja",
            rating: 4.7
        )
    ]
}
