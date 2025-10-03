import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @State private var selectedCategory: SearchCategory = .products
    @State private var productCounts: [Int: Int] = [:]
    @State private var animationDelay: Double = 0
    
    @State private var isLoading: Bool = false
    @State private var displayedProducts: [Product] = []
    @State private var displayedStores: [Store] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var searchAnimationDelay: Double = 0
    @Environment(\.dismiss) private var dismiss

    init(searchText: Binding<String> = .constant("")) {
        self._searchText = searchText
    }

    // MARK: - Sample Data
    private let allProducts: [Product] = [
        Product(
            id: 1,
            name: "Pizza",
            shop: "FreshMart",
            weight: "500g",
            price: "$4.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png"
        ),
        Product(
            id: 2,
            name: "Tres leches",
            shop: "EcoFruit",
            weight: "1kg",
            price: "$2.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (13).png"
        ),
        Product(
            id: 3,
            name: "Batido de mamey",
            shop: "TropicalFresh",
            weight: "2 unidades",
            price: "$6.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (17).png"
        ),
        Product(
            id: 4,
            name: "Arroz con pescado y papas fritas",
            shop: "Berry Farm",
            weight: "250g",
            price: "$3.99",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (14).png"
        ),
        Product(
            id: 6,
            name: "Spaguetti",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (11).png"
        ),
        Product(
            id: 7,
            name: "Cheese Cake",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (15).png"
        ),
        Product(
            id: 8,
            name: "Batido de fresa",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Pasted Graphic.png"
        ),
        Product(
            id: 9,
            name: "Carne de res y vegetales",
            shop: "GreenGarden",
            weight: "300g",
            price: "$5.49",
            imageUrl: "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (12).png"
        )
    ]

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
        // Cancel any in-flight search
        searchTask?.cancel()

        // If text is empty, reset immediately
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isLoading = false
            displayedProducts = allProducts
            displayedStores = allStores
            resetSearchAnimation()
            return
        }

        isLoading = true
        // Reset animation state
        searchAnimationDelay = 0

        searchTask = Task { [text] in
            // Simula latencia de red (1.7s)
            try? await Task.sleep(nanoseconds: 1700_000_000)
            if Task.isCancelled { return }

            // Filtra según el texto
            let products = allProducts.filter { p in
                p.name.localizedCaseInsensitiveContains(text) ||
                p.shop.localizedCaseInsensitiveContains(text)
            }
            let stores = allStores.filter { s in
                s.name.localizedCaseInsensitiveContains(text)
            }

            await MainActor.run {
                // Mantén la categoría elegida, pero refresca ambas colecciones
                displayedProducts = products
                displayedStores = stores
                isLoading = false
                
                // Trigger search animation
                triggerSearchAnimation()
            }
        }
    }
    
    private func triggerSearchAnimation() {
        searchAnimationDelay = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let itemCount = selectedCategory == .products ? displayedProducts.count : displayedStores.count
            searchAnimationDelay = Double(itemCount) * 0.15 + 0.2
        }
    }
    
    private func resetSearchAnimation() {
        searchAnimationDelay = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let itemCount = selectedCategory == .products ? allProducts.count : allStores.count
            searchAnimationDelay = Double(itemCount) * 0.1 + 0.1
        }
    }

    // MARK: - Computed Properties
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return allProducts
        }
        return displayedProducts
    }

    private var filteredStores: [Store] {
        if searchText.isEmpty {
            return allStores
        }
        return displayedStores
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo consistente para toda la vista
                Color(.systemBackground)
                    .ignoresSafeArea()
                
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
                            } else if isLoading {
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
                }.scrollEdgeEffectStyle(.hard, for: .top)
                
                // Loading overlay
                if isLoading {
                    VStack(spacing: 16) {
                        // Placeholder para el Lottie loader
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                        
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
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Atrás")
                                .font(.system(size: 16, weight: .medium))
                        }
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
        }
        .onAppear {
            // Estado inicial
            displayedProducts = allProducts
            displayedStores = allStores
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
                searchAnimationDelay = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    triggerSearchAnimation()
                }
            }
        }
        .navigationTitle("Buscar")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
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
                .opacity(searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 1 : 0) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 1 : 0)
                )
                .scaleEffect(searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 1 : 0.95) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 1 : 0.95)
                )
                .offset(y: searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 0 : 10) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 0 : 10)
                )
                .animation(
                    .easeOut(duration: 0.8)
                    .delay(Double(index) * (searchText.isEmpty ? 0.05 : 0.12)),
                    value: searchText.isEmpty ? animationDelay : searchAnimationDelay
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
                .opacity(searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 1 : 0) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 1 : 0)
                )
                .scaleEffect(searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 1 : 0.95) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 1 : 0.95)
                )
                .offset(y: searchText.isEmpty ? 
                    (animationDelay > Double(index) * 0.1 ? 0 : 15) :
                    (searchAnimationDelay > Double(index) * 0.15 ? 0 : 15)
                )
                .animation(
                    .easeOut(duration: 0.8)
                    .delay(Double(index) * (searchText.isEmpty ? 0.08 : 0.12)),
                    value: searchText.isEmpty ? animationDelay : searchAnimationDelay
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

