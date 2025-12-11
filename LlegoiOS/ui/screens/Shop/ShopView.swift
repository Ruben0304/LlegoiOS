import SwiftUI

struct ShopView: View {
    @StateObject private var viewModel = ShopViewModel()
    @State private var productCounts: [String: Int] = [:]
    @State private var showFiltersSheet = false
    @State private var showSortOptions = false
    @State private var animationDelay: Double = 0
    @State private var selectedProduct: Product? = nil

    // Parámetros opcionales para filtrado inicial
    let initialCategory: String?

    init(category: String? = nil) {
        self.initialCategory = category
    }

    private var totalCartItems: Int {
        productCounts.values.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WelcomeGradientBackground()
                    .ignoresSafeArea()

                // Contador de resultados
                if !viewModel.isLoading {
                  
                }

                // Contenido principal
                if viewModel.isLoading {
                    loadingState
                } else if case .error(let message) = viewModel.state {
                    errorState(message: message)
                } else if viewModel.filteredProducts.isEmpty {
                    emptyState
                } else {
                    productsGrid
                }
            }
            .onAppear {
                if let category = initialCategory {
                    viewModel.selectedCategory = category
                }
                viewModel.loadProducts()
            }
            .sheet(isPresented: $showFiltersSheet) {
                FiltersSheet(
                    maxDistance: $viewModel.maxDistance,
                    selectedCategory: $viewModel.selectedCategory,
                    onApply: {
                        showFiltersSheet = false
                        viewModel.applyFilters()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSortOptions) {
                SortOptionsSheet(
                    sortOption: $viewModel.sortOption,
                    onApply: {
                        showSortOptions = false
                        viewModel.applySort()
                    }
                )
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
            .toolbar{
                ToolbarItem{
                    Button(action: {
                        showFiltersSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Filtros")
                                .font(.system(size: 14, weight: .semibold))
                            if viewModel.hasActiveFilters {
                                Circle()
                                    .fill(Color.llegoPrimary)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
                ToolbarSpacer(.fixed)
                ToolbarItem{
                    Button(action: {
                        showSortOptions = true
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.llegoPrimary)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .navigationTitle("Tienda")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $viewModel.searchQuery,
                placement: .toolbar,
                prompt: "Buscar productos..."
            )
        }
    }

 
    // MARK: - Results Counter
    

     private var productsGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                alignment: .center,
                spacing: 20
            ) {
                ForEach(Array(viewModel.filteredProducts.enumerated()), id: \.element.id) { index, product in
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedProduct = product
                    }
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
            .padding(.top, 8)
        }
        .onAppear {
            animationDelay = Double(viewModel.filteredProducts.count) * 0.1 + 0.1
        }
        .onChange(of: viewModel.filteredProducts.count) { _ in
            animationDelay = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animationDelay = Double(viewModel.filteredProducts.count) * 0.1 + 0.1
            }
        }
        .fullScreenCover(item: $selectedProduct) { product in
            ProductShowcaseView(product: product)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icono ilustrativo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary.opacity(0.1),
                                Color.llegoAccent.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary.opacity(0.7),
                                Color.llegoAccent.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 8)

            // Título
            Text("No encontramos productos")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.llegoPrimary)
                .multilineTextAlignment(.center)

            // Descripción
            Text(emptyStateMessage)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            // Botón de acción
            if viewModel.hasActiveFilters || !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    viewModel.selectedCategory = nil
                    viewModel.maxDistance = 50
                    viewModel.applyFilters()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Limpiar filtros")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: 220)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoPrimary.opacity(0.85)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var emptyStateMessage: String {
        if !viewModel.searchQuery.isEmpty {
            return "No hay productos que coincidan con \"\(viewModel.searchQuery)\". Intenta con otros términos de búsqueda."
        } else if viewModel.hasActiveFilters {
            return "No hay productos disponibles con los filtros seleccionados. Prueba ajustar tus criterios de búsqueda."
        } else {
            return "Aún no hay productos disponibles en la tienda. Vuelve a revisar más tarde."
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("Cargando...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") {
                viewModel.loadProducts()
            }
            .frame(height: 50)
            .frame(maxWidth: 200)
            .buttonStyle(.glassProminent)
            .tint(.llegoPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category Chip Component
private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .llegoPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.llegoPrimary : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.llegoPrimary, lineWidth: isSelected ? 0 : 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filters Sheet (Advanced Filters)
private struct FiltersSheet: View {
    @Binding var maxDistance: Double
    @Binding var selectedCategory: String?
    let onApply: () -> Void
    @State private var tempDistance: Double
    @State private var tempCategory: String?

    let categories = [
        "Italiana",
        "Platos Fuertes",
        "Vegetariana",
        "Batidos y Cócteles",
        "Bebidas Enlatadas",
        "Botellas"
    ]

    init(maxDistance: Binding<Double>, selectedCategory: Binding<String?>, onApply: @escaping () -> Void) {
        self._maxDistance = maxDistance
        self._selectedCategory = selectedCategory
        self.onApply = onApply
        self._tempDistance = State(initialValue: maxDistance.wrappedValue)
        self._tempCategory = State(initialValue: selectedCategory.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Distancia
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Radio de búsqueda")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.onSurfaceColor)
                                Spacer()
                                Text(tempDistance < 50 ? "\(Int(tempDistance)) km" : "Sin límite")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.llegoPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.llegoAccent.opacity(0.15))
                                    )
                            }

                            // Mapa interactivo con radio
                            RadiusMapView(radiusKm: $tempDistance)

                            // Cuadrito informativo
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.llegoAccent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ahorra en envíos")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.llegoPrimary)

                                    Text("Mientras más cerca busques, menores serán los costos de entrega")
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.llegoAccent.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.llegoAccent.opacity(0.2), lineWidth: 1)
                            )

                            // Slider estilizado
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(tempDistance > 1 ? .llegoPrimary : .gray.opacity(0.3))
                                        .onTapGesture {
                                            if tempDistance > 1 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    tempDistance = max(1, tempDistance - 1)
                                                }
                                            }
                                        }

                                    Slider(value: $tempDistance, in: 1...50, step: 1)
                                        .tint(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.llegoPrimary,
                                                    Color.llegoAccent
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )

                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(tempDistance < 50 ? .llegoPrimary : .gray.opacity(0.3))
                                        .onTapGesture {
                                            if tempDistance < 50 {
                                                withAnimation(.spring(response: 0.3)) {
                                                    tempDistance = min(50, tempDistance + 1)
                                                }
                                            }
                                        }
                                }

                                // Presets de distancia
                                HStack(spacing: 8) {
                                    ForEach([5, 10, 20, 50], id: \.self) { preset in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                tempDistance = Double(preset)
                                            }
                                        }) {
                                            Text(preset == 50 ? "Sin límite" : "\(preset) km")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(
                                                    Int(tempDistance) == preset ? .white : .llegoPrimary
                                                )
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(
                                                            Int(tempDistance) == preset
                                                                ? Color.llegoPrimary
                                                                : Color.llegoAccent.opacity(0.15)
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

                        // Categorías
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Categoría")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.onSurfaceColor)

                            VStack(spacing: 8) {
                                // Opción "Todas"
                                FilterOptionRow(
                                    title: "Todas las categorías",
                                    isSelected: tempCategory == nil,
                                    onTap: {
                                        tempCategory = nil
                                    }
                                )

                                ForEach(categories, id: \.self) { category in
                                    FilterOptionRow(
                                        title: category,
                                        isSelected: tempCategory == category,
                                        onTap: {
                                            tempCategory = category
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(.white)
                        .cornerRadius(12)
                    }
                    .padding(16)
                }


                    HStack(spacing: 12) {
                        Button(action: {
                            tempDistance = 50
                            tempCategory = nil
                        }) {
                            Text("Limpiar")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 35)
                        }
                        .buttonStyle(.glass)

                        Button(action: {
                            maxDistance = tempDistance
                            selectedCategory = tempCategory
                            onApply()
                        }) {
                            Text("Aplicar Filtros")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 35)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.llegoPrimary)
                    }
                    .padding(16)
                
            }
//            .background(Color.llegoBackground)
//            .navigationTitle("Filtros")
//            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Filter Option Row
private struct FilterOptionRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.onSurfaceColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.llegoPrimary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(isSelected ? Color.llegoPrimary.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Options Sheet
private struct SortOptionsSheet: View {
    @Binding var sortOption: SortOption
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Ordenar por")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.onSurfaceColor)
                Spacer()
            }
            .padding(20)

            Divider()

            // Opciones
            VStack(spacing: 0) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        onApply()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: option.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(sortOption == option ? .llegoPrimary : .gray)
                                .frame(width: 24)

                            Text(option.displayName)
                                .font(.system(size: 16, weight: sortOption == option ? .semibold : .regular))
                                .foregroundColor(sortOption == option ? .llegoPrimary : .onSurfaceColor)

                            Spacer()

                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.llegoPrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(sortOption == option ? Color.llegoPrimary.opacity(0.06) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if option != SortOption.allCases.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
        
    }
}

#Preview {
    ShopView()
}
