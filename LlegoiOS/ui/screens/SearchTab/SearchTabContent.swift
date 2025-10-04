//import SwiftUI
//
//struct SearchTabContent: View {
//    @State private var productCounts: [String: Int] = [:]
//    @State private var selectedCategory: SearchCategory = .products
//    @State private var selectedStore: Store? = nil
//
//    // Sample products data for search
//
//    // Sample stores data
//    private let allStores: [Store] = [
//        Store(
//            id: "1",
//            name: "FreshMart Premium",
//            etaMinutes: 25,
//            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
//            address: "Calle 23 #456, Vedado",
//            rating: 4.8
//        ),
//        Store(
//            id: "2",
//            name: "EcoFruit Orgánico",
//            etaMinutes: 30,
//            logoUrl: "https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=500&h=200&fit=crop&crop=center",
//            address: "Av. 5ta #789, Miramar",
//            rating: 4.6
//        ),
//        Store(
//            id: "3",
//            name: "TropicalFresh Market",
//            etaMinutes: 20,
//            logoUrl: "https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1506617420156-8e4536971650?w=500&h=200&fit=crop&crop=center",
//            address: "Calle 10 #234, Plaza",
//            rating: 4.9
//        ),
//        Store(
//            id: "4",
//            name: "Berry Farm Co.",
//            etaMinutes: 35,
//            logoUrl: "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=500&h=200&fit=crop&crop=center",
//            address: "Calle L #567, Vedado",
//            rating: 4.5
//        ),
//        Store(
//            id: "5",
//            name: "CitrusMax Express",
//            etaMinutes: 15,
//            logoUrl: "https://images.unsplash.com/photo-1587334207814-e80e8e0adf11?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1597714026720-8f74c62310c9?w=500&h=200&fit=crop&crop=center",
//            address: "Av. Paseo #890, Nuevo Vedado",
//            rating: 4.7
//        ),
//        Store(
//            id: "6",
//            name: "GreenGarden Local",
//            etaMinutes: 40,
//            logoUrl: "https://images.unsplash.com/photo-1516594798947-e65505dbb29d?w=200&h=200&fit=crop&crop=center",
//            bannerUrl: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500&h=200&fit=crop&crop=center",
//            address: "Calle 42 #123, Playa",
//            rating: 4.3
//        )
//    ]
//
//    // Computed property to filter products based on search text
////    private var filteredProducts: [Product] {
////        if searchText.isEmpty {
////            return allProducts
////        } else {
////            return allProducts.filter { product in
////                product.name.localizedCaseInsensitiveContains(searchText) ||
////                product.shop.localizedCaseInsensitiveContains(searchText)
////            }
////        }
////    }
//
//    // Computed property to filter stores based on search text
//    private var filteredStores: [Store] {
//        if searchText.isEmpty {
//            return allStores
//        } else {
//            return allStores.filter { store in
//                store.name.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//    }
//
//    // This will be passed from the parent view
//    @Binding var searchText: String
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Category Picker
//            Picker("Categoría", selection: $selectedCategory) {
//                ForEach(SearchCategory.allCases, id: \.self) { category in
//                    Text(category.rawValue).tag(category)
//                }
//            }
//            .pickerStyle(.segmented)
//            .padding(.horizontal, 16)
//            .padding(.top, 16)
//            .padding(.bottom, 12)
//
//            // Content based on selected category
//            ScrollView {
//                switch selectedCategory {
//                case .products:
//                    productsGrid
//                case .stores:
//                    storesGrid
//                }
//
//                // Additional spacing for navigation
//                Spacer().frame(height: 100)
//
//                // Navigation link for Store Detail
//                NavigationLink(
//                    destination: selectedStore.map { StoreDetailView(store: $0) },
//                    isActive: Binding(
//                        get: { selectedStore != nil },
//                        set: { if !$0 { selectedStore = nil } }
//                    )
//                ) {
//                    EmptyView()
//                }
//                .hidden()
//            }
//        }
//        .navigationTitle("Buscar")
//        .background(Color.llegoBackground.ignoresSafeArea())
//    }
//
//    // MARK: - Products Grid
//    private var productsGrid: some View {
//        Group {
//            if filteredProducts.isEmpty && !searchText.isEmpty {
//                emptyProductsState
//            } else if searchText.isEmpty {
//                searchPromptState
//            } else {
//                LazyVGrid(columns: [
//                    GridItem(.flexible(), spacing: 16),
//                    GridItem(.flexible(), spacing: 16)
//                ], spacing: 16) {
//                    ForEach(filteredProducts) { product in
//                        ProductCard(
//                            product: product,
//                            count: Binding(
//                                get: { productCounts[product.id] ?? 0 },
//                                set: { newValue in
//                                    if newValue > 0 {
//                                        productCounts[product.id] = newValue
//                                    } else {
//                                        productCounts.removeValue(forKey: product.id)
//                                    }
//                                }
//                            ),
//                            onIncrement: {
//                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                    productCounts[product.id] = (productCounts[product.id] ?? 0) + 1
//                                }
//                            },
//                            onDecrement: {
//                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                    let currentCount = productCounts[product.id] ?? 0
//                                    if currentCount > 0 {
//                                        if currentCount == 1 {
//                                            productCounts.removeValue(forKey: product.id)
//                                        } else {
//                                            productCounts[product.id] = currentCount - 1
//                                        }
//                                    }
//                                }
//                            }
//                        )
//                        .transition(.scale.combined(with: .opacity))
//                    }
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 8)
//                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredProducts.count)
//            }
//        }
//    }
//
//    // MARK: - Stores Grid
//    private var storesGrid: some View {
//        Group {
//            if filteredStores.isEmpty && !searchText.isEmpty {
//                emptyStoresState
//            } else if searchText.isEmpty {
//                searchPromptStoresState
//            } else {
//                LazyVGrid(columns: [
//                    GridItem(.flexible(), spacing: 16)
//                ], spacing: 16) {
//                    ForEach(filteredStores) { store in
//                        StoreCard(
//                            storeName: store.name,
//                            etaMinutes: store.etaMinutes,
//                            logoUrl: store.logoUrl,
//                            bannerUrl: store.bannerUrl,
//                            address: store.address,
//                            rating: store.rating,
//                            size: .expanded
//                        )
//                        .transition(.scale.combined(with: .opacity))
//                        .onTapGesture {
//                            selectedStore = store
//                        }
//                    }
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 8)
//                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredStores.count)
//            }
//        }
//    }
//
//    // MARK: - Empty States
//    private var emptyProductsState: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "cart.fill.badge.questionmark")
//                .font(.system(size: 64, weight: .light))
//                .foregroundStyle(
//                    LinearGradient(
//                        colors: [Color.llegoPrimary, Color.llegoAccent],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .padding(.bottom, 8)
//
//            Text("No se encontraron productos")
//                .font(.system(size: 24, weight: .bold, design: .rounded))
//                .foregroundColor(Color.llegoPrimary)
//
//            Text("Intenta con otros términos de búsqueda")
//                .font(.system(size: 16, weight: .medium, design: .rounded))
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top, 120)
//        .padding(.horizontal, 32)
//    }
//
//    private var emptyStoresState: some View {
//        VStack(spacing: 16) {
//            Image(systemName: "storefront.fill")
//                .font(.system(size: 64, weight: .light))
//                .foregroundStyle(
//                    LinearGradient(
//                        colors: [Color.llegoPrimary, Color.llegoAccent],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .padding(.bottom, 8)
//
//            Text("No se encontraron negocios")
//                .font(.system(size: 24, weight: .bold, design: .rounded))
//                .foregroundColor(Color.llegoPrimary)
//
//            Text("Intenta con otros términos de búsqueda")
//                .font(.system(size: 16, weight: .medium, design: .rounded))
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top, 120)
//        .padding(.horizontal, 32)
//    }
//
//    private var searchPromptState: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "magnifyingglass.circle.fill")
//                .font(.system(size: 72, weight: .light))
//                .foregroundStyle(
//                    LinearGradient(
//                        colors: [Color.llegoPrimary.opacity(0.8), Color.llegoAccent],
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
//                .shadow(color: Color.llegoAccent.opacity(0.3), radius: 12, x: 0, y: 6)
//                .padding(.bottom, 12)
//
//            VStack(spacing: 8) {
//                Text("Busca productos")
//                    .font(.system(size: 28, weight: .bold, design: .rounded))
//                    .foregroundColor(Color.llegoPrimary)
//
//                Text("Encuentra tus productos favoritos")
//                    .font(.system(size: 17, weight: .medium, design: .rounded))
//                    .foregroundColor(.secondary)
//            }
//
//            // Popular searches suggestions
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Búsquedas populares")
//                    .font(.system(size: 14, weight: .semibold, design: .rounded))
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 20)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(["Aguacate", "Plátano", "Mango", "Fresas"], id: \.self) { suggestion in
//                            Button(action: {
//                                searchText = suggestion
//                            }) {
//                                HStack(spacing: 6) {
//                                    Image(systemName: "magnifyingglass")
//                                        .font(.system(size: 12, weight: .semibold))
//                                    Text(suggestion)
//                                        .font(.system(size: 15, weight: .medium, design: .rounded))
//                                }
//                                .foregroundColor(Color.llegoPrimary)
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 10)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 20)
//                                        .fill(Color.white)
//                                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
//                                )
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                }
//            }
//            .padding(.top, 24)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top, 80)
//    }
//
//    private var searchPromptStoresState: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "storefront.circle.fill")
//                .font(.system(size: 72, weight: .light))
//                .foregroundStyle(
//                    LinearGradient(
//                        colors: [Color.llegoPrimary.opacity(0.8), Color.llegoAccent],
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
//                .shadow(color: Color.llegoAccent.opacity(0.3), radius: 12, x: 0, y: 6)
//                .padding(.bottom, 12)
//
//            VStack(spacing: 8) {
//                Text("Busca negocios")
//                    .font(.system(size: 28, weight: .bold, design: .rounded))
//                    .foregroundColor(Color.llegoPrimary)
//
//                Text("Encuentra tus tiendas favoritas")
//                    .font(.system(size: 17, weight: .medium, design: .rounded))
//                    .foregroundColor(.secondary)
//            }
//
//            // Popular stores suggestions
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Tiendas populares")
//                    .font(.system(size: 14, weight: .semibold, design: .rounded))
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 20)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(["FreshMart", "EcoFruit", "TropicalFresh"], id: \.self) { suggestion in
//                            Button(action: {
//                                searchText = suggestion
//                            }) {
//                                HStack(spacing: 6) {
//                                    Image(systemName: "storefront")
//                                        .font(.system(size: 12, weight: .semibold))
//                                    Text(suggestion)
//                                        .font(.system(size: 15, weight: .medium, design: .rounded))
//                                }
//                                .foregroundColor(Color.llegoPrimary)
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 10)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 20)
//                                        .fill(Color.white)
//                                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
//                                )
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                }
//            }
//            .padding(.top, 24)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.top, 80)
//    }
//}
