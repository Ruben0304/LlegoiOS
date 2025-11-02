import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum DayMoment: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case lateNight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast:
            return "Desayuno"
        case .lunch:
            return "Almuerzo"
        case .lateNight:
            return "Cena"
        }
    }

    var sectionTitle: String {
        switch self {
        case .breakfast:
            return "Sabores para comenzar tu día"
        case .lunch:
            return "Listos para el almuerzo"
        case .lateNight:
            return "Tentaciones nocturnas"
        }
    }

    var subtitle: String {
        switch self {
        case .breakfast:
            return "Energía suave para la mañana"
        case .lunch:
            return "Tus favoritos del mediodía"
        case .lateNight:
            return "Antojos para cerrar el día"
        }
    }

    var emoji: String {
        switch self {
        case .breakfast:
            return "🌅"
        case .lunch:
            return "☀️"
        case .lateNight:
            return "🌙"
        }
    }

    var accentColor: Color {
        switch self {
        case .breakfast:
            return Color(red: 243/255, green: 158/255, blue: 72/255)
        case .lunch:
            return Color(red: 220/255, green: 121/255, blue: 65/255)
        case .lateNight:
            return Color(red: 118/255, green: 108/255, blue: 201/255)
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .breakfast:
            return [
                Color(red: 255/255, green: 245/255, blue: 225/255),
                Color(red: 255/255, green: 228/255, blue: 183/255)
            ]
        case .lunch:
            return [
                Color(red: 255/255, green: 242/255, blue: 233/255),
                Color(red: 255/255, green: 222/255, blue: 207/255)
            ]
        case .lateNight:
            return [
                Color(red: 235/255, green: 236/255, blue: 253/255),
                Color(red: 222/255, green: 226/255, blue: 247/255)
            ]
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var order: Int {
        switch self {
        case .breakfast:
            return 0
        case .lunch:
            return 1
        case .lateNight:
            return 2
        }
    }

    var keywords: [String] {
        switch self {
        case .breakfast:
            return ["breakfast", "desayuno", "coffee", "café", "pan", "bread", "juice", "huevo", "omelette", "bagel", "smoothie"]
        case .lunch:
            return ["almuerzo", "lunch", "burger", "sandwich", "pollo", "rice", "arroz", "pasta", "pizza", "ensalada", "salad"]
        case .lateNight:
            return ["late", "night", "nocturno", "postre", "dessert", "snack", "taco", "wrap", "sushi", "helado"]
        }
    }

    func fallbackRange(total: Int) -> Range<Int> {
        guard total > 0 else { return 0..<0 }
        if total <= DayMoment.allCases.count {
            return 0..<total
        }

        let segments = DayMoment.allCases.count
        let baseSize = max(1, total / segments)
        let remainder = total % segments
        var start = order * baseSize + min(order, remainder)
        var length = baseSize

        if order < remainder {
            length += 1
        }

        if start >= total {
            start = max(0, total - baseSize)
        }

        let end = min(total, start + length)
        return start..<end
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var productCounts: [String: Int] = [:]
    @State private var searchText: String = ""
    @State private var navigateToPlans = false
    @State private var navigateToCart = false
    @State private var navigateToWallet = false
    @State private var navigateToProductDetails: Bool = false
    @State private var selectedProduct: Product? = nil
    @State private var selectedStore: Store? = nil
    @State private var navigateToProfile = false
    @State private var selectedMoment: DayMoment = .breakfast
    @State private var navigateToShop = false
    @State private var shopInitialCategory: String? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var navigateToTutorials = false
    @State private var selectedTutorial: Tutorial? = nil

    private var momentProducts: [Product] {
        products(for: selectedMoment)
    }

    private func products(for moment: DayMoment) -> [Product] {
        let allProducts = viewModel.products
        guard !allProducts.isEmpty else { return [] }

        let keywordMatches = allProducts.filter { product in
            moment.keywords.contains { keyword in
                product.name.localizedCaseInsensitiveContains(keyword)
            }
        }

        if keywordMatches.count >= 4 {
            return Array(keywordMatches.prefix(8))
        }

        let fallbackRange = moment.fallbackRange(total: allProducts.count)
        let fallbackProducts: [Product]

        if fallbackRange.isEmpty {
            fallbackProducts = allProducts
        } else {
            fallbackProducts = Array(allProducts[fallbackRange])
        }

        if keywordMatches.isEmpty {
            return Array(fallbackProducts.prefix(8))
        } else {
            var combined = keywordMatches
            for product in fallbackProducts where !combined.contains(product) {
                combined.append(product)
            }
            return Array(combined.prefix(8))
        }
    }

    var body: some View {
        NavigationStack {
            CurvedBackground {
                ZStack(alignment: .top) {
                    // Contenido principal
                    VStack(spacing: 0) {
                        // Ubicación
                        VStack(spacing: 5) {
                            Text("Ubicación actual")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.llegoSurfaceVariant)

                            HStack(spacing: 4) {
                                Text("La Habana, Cuba")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.llegoAccent)

                                Image(systemName: "location.fill")
                                    .foregroundColor(Color.llegoAccent)
                                    .font(.system(size: 16))
                            }
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(.vertical, 15)
                        .zIndex(0)

                        // Contenido scrolleable
                        ScrollView {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: proxy.frame(in: .named("homeScroll")).minY
                                )
                            }
                            .frame(height: 0)

                            VStack(alignment: .leading, spacing: 20) {
                                // Loading state
                                if viewModel.isLoading {
                                    VStack(spacing: 20) {
                                        LottieView(name: "loader")
                                            .frame(width: 170, height: 170)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.top, 100)
                                }
                                // Error state
                                else if case .error(let message) = viewModel.state {
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
                                            viewModel.loadHomeData()
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.llegoPrimary)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.top, 100)
                                }
                                // Success state
                                else if case .success = viewModel.state {
                                    // Product Section
                                    ProductSection(
                                        products: viewModel.products,
                                        productCounts: $productCounts,
                                        cardWidth: 155,
                                        cardHeight: 310,
                                        onSeeMoreClick: {
                                            shopInitialCategory = nil
                                            navigateToShop = true
                                        },
                                        onProductTap: { product in
                                            selectedProduct = product
                                        }
                                    )

                                    // Store Section
                                    StoreSection(
                                        stores: viewModel.stores,
                                        onSeeMoreTap: {
                                            print("Ver más tiendas clicked!")
                                        },
                                        onStoreTap: { store in
                                            selectedStore = store
                                        }
                                    )

                                    // Tutorial Section
                                    TutorialSection(
                                        tutorials: viewModel.tutorials,
                                        cardWidth: 200,
                                        cardHeight: 220,
                                        onSeeMoreClick: {
                                            navigateToTutorials = true
                                        },
                                        onTutorialTap: { tutorial in
                                            selectedTutorial = tutorial
                                        }
                                    )
                                    .padding(.top, 8)

                                    MomentOfDayDiscoverySection(
                                        selectedMoment: $selectedMoment,
                                        products: momentProducts,
                                        productCounts: $productCounts,
                                        onSeeMoreTap: {
                                            print("Ver todo \(selectedMoment.displayName)")
                                        },
                                        onProductTap: { product in
                                            selectedProduct = product
                                        }
                                    )
                                    .padding(.top, 8)

                                    // Category Selection Card
//                                    CategorySelectionCard()
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 8)

                                    // Promo Section
                                    PromoSection(
                                        onSubscriptionTap: {
                                            navigateToPlans = true
                                        },
                                        onFamilyPaymentTap: {
                                            print("Family payment tapped!")
                                            // TODO: Navigate to family payment info
                                        }
                                    )
                                    .padding(.top, 8)
                                }

                              

                                // Navigation link for Plans & Pricing
                                NavigationLink(
                                    destination: PlansAndPricingView(),
                                    isActive: $navigateToPlans
                                ) {
                                    EmptyView()
                                }
                                .hidden()

                                // Navigation link for Cart (kept for compatibility — replaced by fullScreenCover below)
                                // The actual presentation uses a fullScreenCover so the Cart appears modally like CheckoutView
                                EmptyView()

                                // NOTE: Product and Store details are presented modally using fullScreenCover below.


                            }
                        }
                        .coordinateSpace(name: "homeScroll")
                    }

                    // Semicircular Slider - Posición absoluta fija
                    SemicircularSlider(onCategoryTap: { category in
                        shopInitialCategory = category
                        navigateToShop = true
                    })
                        .frame(maxWidth: .infinity)
                        .position(x: UIScreen.main.bounds.width / 2, y: 90)
                        .zIndex(2)
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    let currentOffset = -offset
                    if scrollOffset != currentOffset {
                        scrollOffset = currentOffset
                        print("📜 Scroll offset: \(String(format: "%.2f", currentOffset))")
                    }
                }
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        navigateToWallet = true
                    }) {
                        HStack(spacing: 4) {
                            Image("cerdito")
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("$\(String(format: "%.2f", walletViewModel.balance))")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
                
                // Botón del carrito a la derecha
                ToolbarItem {
                    Button(action: {
                        navigateToCart = true
                    }) {
                        Image(systemName: "cart.fill")
                    }.badge(cartManager.cartItemCount)
                }
                ToolbarSpacer(.fixed)
                // Botón de perfil a la derecha
                ToolbarItem{
                    Button(action: {
                        navigateToProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                if case .idle = viewModel.state {
                    viewModel.loadHomeData()
                }
                walletViewModel.loadBalance()
                productCounts = cartManager.localItems.reduce(into: [:]) { result, item in
                    result[item.productId] = item.quantity
                }
            }
            .onReceive(cartManager.$localItems) { items in
                productCounts = items.reduce(into: [:]) { result, item in
                    result[item.productId] = item.quantity
                }
            }

        }
        
//        .navigationViewStyle(StackNavigationViewStyle())
        // Present CartView modally using fullScreenCover to match Cart -> Checkout behavior
        // Wrap in NavigationView so the modal has its own navigation bar (title + toolbar)
        .fullScreenCover(isPresented: $navigateToCart) {
            NavigationView {
                CartView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present WalletView modally
        .fullScreenCover(isPresented: $navigateToWallet) {
            NavigationView {
                WalletView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Navigate to Product detail when a product is selected
        .navigationDestination(item: $selectedProduct) { product in
            TestProductView(product: product)
        }

        // Present Store detail modally when a store is selected
        .fullScreenCover(item: $selectedStore) { store in
            NavigationView {
                StoreDetailView(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present ProfileView modally
        .fullScreenCover(isPresented: $navigateToProfile) {
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present ShopView modally
        .fullScreenCover(isPresented: $navigateToShop) {
            NavigationView {
                ShopView(category: shopInitialCategory)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present TutorialsView modally
        .fullScreenCover(isPresented: $navigateToTutorials) {
            NavigationView {
                TutorialsView()
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }

        // Present individual tutorial video player modally
        .fullScreenCover(item: $selectedTutorial) { tutorial in
            VideoPlayerView(tutorial: tutorial, onDismiss: {
                selectedTutorial = nil
            })
        }

    }
}

private struct MomentOfDayDiscoverySection: View {
    @Binding var selectedMoment: DayMoment
    let products: [Product]
    @Binding var productCounts: [String: Int]
    let onSeeMoreTap: () -> Void
    var onProductTap: ((Product) -> Void)?

    private let titleColor = Color(red: 27/255, green: 27/255, blue: 27/255)
    private let subtitleColor = Color(red: 74/255, green: 74/255, blue: 74/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .padding(.horizontal, 16)

            momentTabs
                .padding(.horizontal, 16)

            if products.isEmpty {
                emptyState
            } else {
                ProductSection(
                    products: products,
                    productCounts: $productCounts,
                    cardWidth: 155,
                    cardHeight: 310,
                    onSeeMoreClick: onSeeMoreTap,
                    onProductTap: { product in
                        onProductTap?(product)
                    },
                    title: selectedMoment.sectionTitle,
                    actionTitle: "Ver todo",
                    accentColor: selectedMoment.accentColor
                )
            }
        }
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Explora por momento del día")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(titleColor)
                Text(selectedMoment.emoji)
                    .font(.system(size: 22))
            }

            Text(selectedMoment.subtitle)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(subtitleColor)
        }
    }

    private var momentTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DayMoment.allCases) { moment in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedMoment = moment
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(moment.emoji)
                                .font(.system(size: 14))
                            Text(moment.displayName)
                                .font(.system(size: 14, weight: .semibold, design: .default))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(chipBackground(for: moment))
                        )
                        .overlay(
                            Capsule()
                                .stroke(chipBorder(for: moment), lineWidth: 1)
                        )
                        .foregroundColor(chipForeground(for: moment))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No encontramos productos para \(selectedMoment.displayName.lowercased()).")
                .font(.system(size: 15, weight: .semibold, design: .default))
            Text("Prueba otro momento o explora otras secciones mientras actualizamos esta categoría.")
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundColor(subtitleColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipBackground(for moment: DayMoment) -> Color {
        if selectedMoment == moment {
            return moment.accentColor.opacity(0.2)
        } else {
            return Color.white.opacity(0.6)
        }
    }

    private func chipBorder(for moment: DayMoment) -> Color {
        if selectedMoment == moment {
            return moment.accentColor.opacity(0.6)
        } else {
            return moment.accentColor.opacity(0.2)
        }
    }

    private func chipForeground(for moment: DayMoment) -> Color {
        if selectedMoment == moment {
            return moment.accentColor
        } else {
            return titleColor
        }
    }
}
