import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    @State private var selectedStore: Store? = nil
    @StateObject private var viewModel = SearchViewModel()
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
        // If text is empty, clear results
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Load categories
        viewModel.loadCategories()

        // Perform search for both products and stores
        viewModel.searchProducts(query: text)
        viewModel.searchStores(query: text)
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
                        VStack(spacing: 32) {
                            if searchText.isEmpty {
                                emptySearchState
                            } else if viewModel.isLoading {
                                // Solo 3 skeletons durante loading
                                SearchSkeleton()
                                    .padding(.top, 20)
                            } else {
                                // Mostrar las 3 secciones
                                searchResultsSections
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        
        .onAppear {
            // Load categories on appear
            viewModel.loadCategories()

            // Estado inicial: keep sample data for empty search
            // If there's already a query, perform it
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                performSearch(with: searchText)
            }
        }
        .onChange(of: searchText) { newValue in
            performSearch(with: newValue)
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

    // MARK: - Search Results Sections
    private var searchResultsSections: some View {
        VStack(spacing: 32) {
            // Sección 1: Categorías (slider horizontal)
            if !viewModel.categories.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categorías")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.categories) { category in
                                CategoryItem(
                                    text: category.name,
                                    imageName: category.imageName,
                                    circleSize: 80
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            // Sección 2: Productos (máximo 3)
            if !filteredProducts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Productos")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        ForEach(Array(filteredProducts.prefix(3))) { product in
                            ProductListItem(product: product)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }

            // Sección 3: Vendedores (lista)
            if !filteredStores.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vendedores")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        ForEach(filteredStores) { store in
                            SellerListItem(store: store)
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    selectedStore = store
                                }
                        }
                    }
                }
            }

            // Mensaje si no hay resultados
            if filteredProducts.isEmpty && filteredStores.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.llegoPrimary, Color.llegoAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 12)

                    Text("No encontramos resultados")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.llegoPrimary)

                    Text("Intenta con otros términos de búsqueda")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
    }
}

