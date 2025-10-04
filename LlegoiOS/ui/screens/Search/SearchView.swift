import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @State private var selectedCategory: SearchCategory = .products
    @State private var productCounts: [String: Int] = [:]
    @State private var animationDelay: Double = 0
    
    // Loading state is provided by the view model
    @StateObject private var viewModel = SearchViewModel()
    // local searchTask removed: debouncing is handled by SearchViewModel
    @State private var searchAnimationDelay: Double = 0
    @State private var selectedStore: Store? = nil
    @Environment(\.dismiss) private var dismiss

    init(searchText: Binding<String> = .constant("")) {
        self._searchText = searchText
    }

    // MARK: - Sample Data
    

    private let allStores: [Store] = [
        Store(id: "1", name: "FreshMart Premium", etaMinutes: 25,
              logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
              address: "Calle 23 #456, Vedado",
              rating: 4.8),
        Store(id: "2", name: "EcoFruit Orgánico", etaMinutes: 30,
              logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
              address: "Av. 5ta #789, Miramar",
              rating: 4.6),
        Store(id: "3", name: "TropicalFresh Market", etaMinutes: 20,
              logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
              address: "Calle 10 #234, Plaza",
              rating: 4.9),
        Store(id: "4", name: "Berry Farm Co.", etaMinutes: 35,
              logoUrl: "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=500&h=200&fit=crop&crop=center",
              address: "Calle L #567, Vedado",
              rating: 4.5),
        Store(id: "5", name: "CitrusMax Express", etaMinutes: 15,
              logoUrl: "https://images.unsplash.com/photo-1587334207814-e80e8e0adf11?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1597714026720-8f74c62310c9?w=500&h=200&fit=crop&crop=center",
              address: "Av. Paseo #890, Nuevo Vedado",
              rating: 4.7),
        Store(id: "6", name: "GreenGarden Local", etaMinutes: 40,
              logoUrl: "https://images.unsplash.com/photo-1516594798947-e65505dbb29d?w=200&h=200&fit=crop&crop=center",
              bannerUrl: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&h=200&fit=crop&crop=center",
              address: "Calle 42 #123, Playa",
              rating: 4.3)
    ]

    // MARK: - Simulated Search
    private func performSearch(with text: String) {
    // Any local animation task was removed; debounce is handled in the view model

        // If text is empty, reset animations and keep sample data
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            resetSearchAnimation()
            return
        }

        // Use the SearchViewModel to perform a real (GraphQL) search.
        // Debounce is handled inside the view model, so the view only triggers searches.
        viewModel.performSearch(query: text, category: selectedCategory)

        // Reset animation for search results
        animationDelay = 0
    }
    
    private func triggerSearchAnimation() {
        searchAnimationDelay = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let itemCount: Int
            if searchText.isEmpty {
                itemCount = 0
            } else {
                itemCount = selectedCategory == .products ? viewModel.products.count : viewModel.stores.count
            }
            searchAnimationDelay = Double(itemCount) * 0.15 + 0.2
        }
    }
    
    private func resetSearchAnimation() {
        searchAnimationDelay = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let itemCount = 0
            searchAnimationDelay = Double(itemCount) * 0.1 + 0.1
        }
    }

    // MARK: - Computed Properties
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return []
        }
        return viewModel.products
    }

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return allStores
        }
        return viewModel.stores
    }

    // MARK: - Body
    var body: some View {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()
//                // Fondo consistente para toda la vista
//                Color(.systemBackground)
//                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Búsquedas populares fijas en la parte superior con glasmorphismo
                    popularSearchesFloating
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    
                    
                    // ScrollView con el contenido principal
                    ScrollView {
                        VStack(spacing: 40) {
                            if searchText.isEmpty {
                                emptySearchState
                            } else if viewModel.isLoading {
                                // Espacio vacío durante loading
                                Spacer()
                                    .frame(height: 200)
                            } else {
                                switch selectedCategory {
                                case .products:
                                    if filteredProducts.isEmpty {
                                        emptyProductsState
                                    } else {
                                        productsGrid
                                    }
                                case .stores:
                                    if filteredStores.isEmpty {
                                        emptyStoresState
                                    } else {
                                        storesGrid
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        LottieView(name: "loader")
                            .frame(width: 120, height: 120)

                        Text("Buscando...")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.llegoPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SearchCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = category
                                }
                            }) {
                                HStack {
                                    Text(category.rawValue)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCategory.rawValue)
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
            }
        
        .onAppear {
            // Estado inicial: keep sample data for empty search
            // If there's already a query, perform it
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.performSearch(query: searchText, category: selectedCategory)
            }
        }
        .onChange(of: searchText) { newValue in
            performSearch(with: newValue)
        }
        .onChange(of: selectedCategory) { _ in
            // Reinicia la animación de aparición al cambiar la categoría
            if searchText.isEmpty {
                animationDelay = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animationDelay = 0.2
                }
            } else {
                // When category changes, re-run the search against the view model
                viewModel.performSearch(query: searchText, category: selectedCategory)
                animationDelay = 0
            }
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            // Trigger animation when loading finishes
            if !isLoading && !searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let itemCount = selectedCategory == .products ?
                        viewModel.products.count : viewModel.stores.count
                    animationDelay = Double(itemCount) * 0.1 + 0.1
                }
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
                .aspectRatio(155.0/310.0, contentMode: .fit)
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
        .onAppear {
            if searchText.isEmpty {
                animationDelay = Double(filteredProducts.count) * 0.1 + 0.1
            }
        }
        .onChange(of: filteredProducts.count) { _ in
            if searchText.isEmpty {
                animationDelay = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animationDelay = Double(filteredProducts.count) * 0.1 + 0.1
                }
            }
        }
    }

    // MARK: - Stores Grid
    private var storesGrid: some View {
        LazyVStack(alignment: .center, spacing: 40) {
            ForEach(Array(filteredStores.enumerated()), id: \.element.id) { index, store in
                StoreCard(
                    storeName: store.name,
                    etaMinutes: store.etaMinutes,
                    logoUrl: store.logoUrl,
                    bannerUrl: store.bannerUrl,
                    address: store.address,
                    rating: store.rating,
                    size: .expanded
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                .onTapGesture {
                    selectedStore = store
                }
                .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 15)
                .animation(
                    .easeOut(duration: 0.6)
                    .delay(Double(index) * 0.05),
                    value: animationDelay
                )
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            if searchText.isEmpty {
                animationDelay = Double(filteredStores.count) * 0.1 + 0.1
            }
        }
        .onChange(of: filteredStores.count) { _ in
            if searchText.isEmpty {
                animationDelay = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animationDelay = Double(filteredStores.count) * 0.1 + 0.1
                }
            }
        }
    }

    // MARK: - Popular Searches Floating
    private var popularSearchesFloating: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Búsquedas populares")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Aguacate", "Plátano", "Mango", "Fresas", "Tomate", "Limón"], id: \.self) { suggestion in
                        Button(action: {
                            searchText = suggestion
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(suggestion)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.llegoPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1) // Pequeño padding para evitar recortes

                // Navigation link for Store Detail
                NavigationLink(
                    destination: selectedStore.map { StoreDetailView(store: $0) },
                    isActive: Binding(
                        get: { selectedStore != nil },
                        set: { if !$0 { selectedStore = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .background(Color.clear) // Asegurar fondo transparente
    }

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: 24) {
            // Icono animado con gradiente
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.llegoAccent.opacity(0.2),
                                Color.llegoPrimary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.llegoPrimary, Color.llegoAccent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.llegoAccent.opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .padding(.top, 40)

            VStack(spacing: 10) {
                Text("¿Qué estás buscando?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
                    .multilineTextAlignment(.center)

                Text("Busca entre miles de productos y negocios")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty Products State
    private var emptyProductsState: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.fill.badge.questionmark")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.llegoPrimary, Color.llegoAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 12)

            Text("No encontramos productos")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)

            Text("Intenta con otros términos de búsqueda")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Empty Stores State
    private var emptyStoresState: some View {
        VStack(spacing: 20) {
            Image(systemName: "storefront.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.llegoPrimary, Color.llegoAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 12)

            Text("No encontramos negocios")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)

            Text("Intenta con otros términos de búsqueda")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

