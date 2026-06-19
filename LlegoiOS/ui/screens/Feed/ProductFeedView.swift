import AVKit
import SwiftUI

struct ProductFeedView: View {
    @StateObject private var viewModel = ProductFeedViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var cartManager = CartManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var showFavoritesSheet = false
    @State private var selectedTutorial: Tutorial? = nil
    @State private var selectedProductId: String?
    @State private var selectedComboId: String?
    @State private var showCart = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gradiente sutil que se sincroniza con HomeView
                feedGradientBackground
                    .ignoresSafeArea()
                    .animation(
                        .easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.isLoading {
                        loadingState
                    } else if case .error(let message) = viewModel.state {
                        errorState(message: message)
                    } else if viewModel.feedSections.isEmpty && viewModel.featuredProducts.isEmpty {
                        emptyState
                    } else {
                        feedContent
                    }
                }
            }
            .toolbar {
                // "Para ti" al lado izquierdo
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Para ti")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color.adaptiveOnBackground(colorScheme))
                            .fixedSize()
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Text("Para ti")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color.adaptiveOnBackground(colorScheme))
                            .fixedSize()
                    }
                }

                // Botón de favoritos
                ToolbarItem(placement: .navigationBarTrailing) {
                    if favoritesManager.favoriteItemCount > 0 {
                        Button(action: { showFavoritesSheet = true }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .badge(favoritesManager.favoriteItemCount)
                        .id("favorites-toolbar-badge-\(favoritesManager.favoriteItemCount)")
                        .accessibilityLabel("Favoritos")
                    } else {
                        Button(action: { showFavoritesSheet = true }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("Favoritos")
                    }
                }

                // Botón de carrito
                ToolbarItem(placement: .navigationBarTrailing) {
                    if cartManager.cartItemCount > 0 {
                        Button(action: {
                            showCart = true
                        }) {
                            Image(systemName: "cart")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .badge(cartManager.cartItemCount)
                        .id("cart-toolbar-badge-\(cartManager.cartItemCount)")
                        .accessibilityLabel("Carrito")
                    } else {
                        Button(action: {
                            showCart = true
                        }) {
                            Image(systemName: "cart")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("Carrito")
                    }
                }
            }
            .sheet(isPresented: $showFavoritesSheet) {
                NavigationView { FavoritesView() }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $selectedTutorial) { tutorial in
                VideoPlayerView(
                    tutorial: tutorial,
                    onDismiss: {
                        selectedTutorial = nil
                    })
            }
            .fullScreenCover(item: $selectedProductId) { productId in
                ProductDetailView(productId: productId)
            }
            .fullScreenCover(item: $selectedComboId) { comboId in
                ComboDetailView(comboId: comboId)
            }
            .fullScreenCover(isPresented: $showCart) {
                CartView()
            }
            .onAppear { viewModel.loadFeed() }
        }
    }

    // MARK: - Feed Gradient Background
    private var feedGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.4)

            // Gradiente sutil que emula el de HomeView pero más suave
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.15), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.3), location: 0.4),
                    .init(
                        color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.95),
                        location: 1.0),
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                categoriesSection.padding(.top, 8)

                ForEach(viewModel.sectionOrder, id: \.self) { slot in
                    feedSlotView(slot)
                }

                // "Más de X" sections from page 2, 3... appear before Explorar
                ForEach(viewModel.moreSections) { section in
                    if !viewModel.filteredProducts(for: section).isEmpty {
                        dynamicSection(section)
                    }
                }

                if viewModel.isLoadingMore {
                    ProgressView().tint(gradientManager.currentAccentColor).padding(.vertical, 20)
                } else if viewModel.hasMoreFeedPages {
                    Color.clear.frame(height: 1)
                        .onAppear { viewModel.loadNextFeedPage() }
                }

                // Explorar always comes last
                if !viewModel.explorarProducts.isEmpty {
                    explorarSection
                }
            }
        }
        .refreshable { await refreshFeed() }
    }

    @ViewBuilder
    private func feedSlotView(_ slot: ProductFeedViewModel.SectionSlot) -> some View {
        switch slot {
        case .paraTi:
            if let section = viewModel.paraTiSection, !section.products.isEmpty {
                featuredProductsSection(section: section)
            }
        case .popularesCerca:
            if let section = viewModel.getSection(.popularesCerca),
               !viewModel.filteredProducts(for: section).isEmpty {
                featuredProductsSectionWithTitle(section: section)
            }
        case .pideDeNuevoInline:
            if let item = viewModel.topReorderItem {
                PideDeNuevoInlineCard(item: item, accentColor: gradientManager.currentAccentColor) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedProductId = item.productId
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        case .dynamicFirst:
            if let firstSection = viewModel.horizontalSections.first,
               !viewModel.filteredProducts(for: firstSection).isEmpty {
                dynamicSection(firstSection)
            }
        case .stores:
            if !viewModel.filteredStores.isEmpty {
                storesSection
            }
        case .combos:
            if !viewModel.combos.isEmpty {
                combosSection
            }
        case .dynamicRest:
            ForEach(Array(viewModel.horizontalSections.dropFirst())) { section in
                if !viewModel.filteredProducts(for: section).isEmpty {
                    dynamicSection(section)
                }
            }
        case .featuredStore:
            if let store = viewModel.featuredStore {
                FeaturedStoreCard(store: store, accentColor: gradientManager.currentAccentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
        case .tutorials:
            if viewModel.showTutorials && !viewModel.tutorials.isEmpty {
                tutorialsSection
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
            }
        case .explorar:
            if !viewModel.explorarProducts.isEmpty {
                explorarSection
            }
        case .destacados:
            creativeCarousel(sectionId: "destacados", titleOverride: "Descubre ofertas para ti")
        case .ofertas:
            creativeCarousel(sectionId: "ofertas")
        }
    }

    // MARK: - Creative Sections (Destacados / Ofertas — paid placements)
    @ViewBuilder
    private func creativeCarousel(sectionId: String, titleOverride: String? = nil) -> some View {
        if let section = viewModel.creativeSections.first(where: { $0.sectionId == sectionId }),
            !section.items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(titleOverride ?? section.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(section.items) { item in
                            CreativeCard(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 10)
        }
    }

    // MARK: - Explorar Section (vertical infinite grid)
    private var explorarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explora otras opciones")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                ForEach(viewModel.explorarProducts) { product in
                    ExplorarProductCard(
                        product: product, accentColor: gradientManager.currentAccentColor
                    )
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedProductId = product.id
                    }
                }
            }
            .padding(.horizontal, 20)

            if viewModel.isLoadingExplorar {
                ProgressView()
                    .tint(gradientManager.currentAccentColor)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            } else if viewModel.hasMoreExplorar {
                Color.clear.frame(height: 1)
                    .onAppear { viewModel.loadMoreExplorar() }
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Categories Section
    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories) { category in
                    let isSelected =
                        category.isAll
                        ? viewModel.selectedCategory == nil
                        : viewModel.selectedCategory == category.id

                    CategoryChip(
                        title: category.name,
                        icon: category.icon,
                        isSelected: isSelected,
                        isFeatured: category.isFeatured,
                        onTap: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.selectCategory(category)
                        },
                        accentColor: gradientManager.currentAccentColor
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Featured Products Section ("Para ti" with large cards)
    private func featuredProductsSection(section: FeedSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.filteredProducts(for: section)) { product in
                        FeaturedProductCard(product: product)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedProductId = product.id
                            }
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Featured Section with Title (small cards + header)
    private func featuredProductsSectionWithTitle(section: FeedSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.filteredProducts(for: section)) { product in
                        SmallProductCard(
                            product: product,
                            accentColor: gradientManager.currentAccentColor,
                            badge: nil
                        )
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedProductId = product.id
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Dynamic Section (renders based on sectionId)
    private func dynamicSection(_ section: FeedSection) -> some View {
        let sectionType = FeedSectionType(rawValue: section.sectionId)
        let products = viewModel.filteredProducts(for: section)

        return VStack(alignment: .leading, spacing: 12) {
            // Section header with optional badge
            HStack {
                HStack(spacing: 8) {
                    Text(section.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    // Badge based on section type
                    sectionBadge(for: sectionType)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            // Horizontal scroll of products
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(products) { product in
                        SmallProductCard(
                            product: product,
                            accentColor: gradientManager.currentAccentColor,
                            badge: productBadge(for: sectionType, product: product)
                        )
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedProductId = product.id
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Section Badge Helper
    @ViewBuilder
    private func sectionBadge(for sectionType: FeedSectionType) -> some View {
        switch sectionType {
        case .trending:
            Text("🔥")
                .font(.system(size: 14))
        case .nuevosLugaresFavoritos:
            Text("Nuevo")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.green))
        case .horaDelDia:
            let hour = Calendar.current.component(.hour, from: Date())
            let icon = hour >= 6 && hour < 12 ? "sun.horizon.fill"
                : hour >= 12 && hour < 20 ? "sun.max.fill"
                : "moon.stars.fill"
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(hour >= 6 && hour < 20 ? .orange : .indigo)
        default:
            EmptyView()
        }
    }

    // MARK: - Product Badge Helper
    private func productBadge(for sectionType: FeedSectionType, product: FeedProduct) -> String? {
        switch sectionType {
        case .cercaTi:
            return product.formattedDistance
        case .trending:
            return "Trending"
        case .nuevosLugaresFavoritos:
            return "Nuevo"
        default:
            return nil
        }
    }

    // MARK: - Tutorials Section
    private var tutorialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aprende a usar Llego")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Spacer()
                Button(action: { viewModel.dismissTutorials() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.tutorials) { tutorial in
                        TutorialFeedCard(
                            tutorial: tutorial, accentColor: gradientManager.currentAccentColor
                        ) {
                            selectedTutorial = tutorial
                        }
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Combos Section
    private var combosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Combos especiales")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    Text("Personaliza tu pedido")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.combos) { feedCombo in
                        ComboCard(
                            combo: feedCombo.toCombo(),
                            onTap: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedComboId = feedCombo.id
                            }
                        )
                        .frame(width: 230)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Pide de Nuevo Section
    private var reorderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Pide de nuevo")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                Spacer()
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.reorderItems) { item in
                        ReorderItemCard(item: item, accentColor: gradientManager.currentAccentColor)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedProductId = item.productId
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Stores Section
    private var storesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Negocios destacados")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Spacer()
                NavigationLink(destination: StoreListView()) {
                    Text("Ver todo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(viewModel.filteredStores) { store in
                        NavigationLink(destination: StoreDetailView(storeId: store.id)) {
                            StoreCircleCard(
                                store: store, accentColor: gradientManager.currentAccentColor)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Refresh
    private func refreshFeed() async {
        await withCheckedContinuation { continuation in
            viewModel.loadFeed(isRefreshing: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { continuation.resume() }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        FullLoadingView(color: gradientManager.currentAccentColor)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "flame")
                        .font(.system(size: 48, weight: .regular))
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    VStack(spacing: 8) {
                        Text("No hay productos destacados")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Vuelve más tarde para ver las mejores ofertas")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            }
            .refreshable { await refreshFeed() }
        }
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
            Button("Reintentar") { viewModel.loadFeed() }
                .frame(height: 50)
                .frame(maxWidth: 200)
                .modifier(GlassProminentButtonModifier())
                .tint(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Store Circle Card
struct StoreCircleCard: View {
    let store: FeedStore
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.cardBackground(colorScheme))
                    .frame(width: 100, height: 100)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.12), radius: 7,
                        x: 0, y: 4)

                if let avatarUrl = store.preferredAvatarSmallUrl {
                    CachedAsyncImage(
                        url: URL(string: avatarUrl),
                        cacheKey: "store_avatar_\(store.id)",
                        content: { image in
                            image.resizable().scaledToFill()
                        },
                        placeholder: { Circle().fill(Color.gray.opacity(0.2)) },
                        failure: {
                            Image(systemName: "storefront")
                                .font(.system(size: 36))
                                .foregroundColor(.gray)
                        }
                    )
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "storefront")
                        .font(.system(size: 36))
                        .foregroundColor(accentColor)
                }
            }

            Text(store.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 36, alignment: .top)
        }
    }
}

private extension FeedProduct {
    var cachedKeyBaja: String { "product_baja_\(id)" }
    var cachedKeyMedia: String { "product_media_\(id)" }
    var cachedBranchAvatarKey: String { "branch_avatar_\(branchId)" }
}

// MARK: - Featured Product Card
struct FeaturedProductCard: View {
    let product: FeedProduct

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            featuredImage

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                if !product.branchName.isEmpty {
                    HStack(spacing: 6) {
                        if let avatarUrl = product.branchAvatarUrl, !avatarUrl.isEmpty {
                            CachedAsyncImage(
                                url: URL(string: avatarUrl),
                                cacheKey: product.cachedBranchAvatarKey,
                                content: { image in image.resizable().scaledToFill() },
                                placeholder: { Circle().fill(Color.white.opacity(0.3)) }
                            )
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        }

                        Text(product.branchName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Text(product.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(height: 44, alignment: .leading)

                HStack {
                    Text(product.formattedPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    if let distance = product.formattedDistance {
                        Text("•").foregroundColor(.white.opacity(0.6))
                        Text(distance)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 280, height: 350)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.12), radius: 7, x: 0, y: 4)
    }

    @ViewBuilder
    private var featuredImage: some View {
        let imageView = CachedAsyncImage(
            url: URL(string: product.imageUrlMedia),
            cacheKey: product.cachedKeyMedia,
            displaySize: CGSize(width: 280, height: 350),
            content: { image in
                image.resizable().scaledToFill()
            },
            placeholder: {
                AdaptiveShimmerView(cornerRadius: 16)
            },
            failure: {
                AdaptiveShimmerView(cornerRadius: 16)
            }
        )
        .frame(width: 280, height: 350)
        .clipped()

        imageView
    }
}

// MARK: - Small Product Card
struct SmallProductCard: View {
    let product: FeedProduct
    let accentColor: Color
    var badge: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                smallCardImage

                // Badge overlay
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(badgeColor))
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(2)
                    .frame(height: 36, alignment: .top)

                Text(product.formattedPrice)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .frame(width: 140, alignment: .leading)
        }
        .frame(width: 140)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 6, x: 0, y: 3)
        )
    }

    private var badgeColor: Color {
        if badge == "Trending" { return .orange }
        if badge == "Nuevo" { return .green }
        return accentColor
    }

    @ViewBuilder
    private var smallCardImage: some View {
        let imageView = CachedAsyncImage(
            url: URL(string: product.imageUrlBaja),
            cacheKey: product.cachedKeyBaja,
            displaySize: CGSize(width: 180, height: 130),
            content: { image in image.resizable().scaledToFill() },
            placeholder: {
                AdaptiveShimmerView(cornerRadius: 12)
            },
            failure: {
                AdaptiveShimmerView(cornerRadius: 12)
            }
        )
        .frame(width: 140, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        imageView
    }
}

// MARK: - Compact Product Card
struct CompactProductCard: View {
    let product: FeedProduct
    let accentColor: Color
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var favoritePulse = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(
                    url: URL(string: product.imageUrlBaja),
                    cacheKey: product.cachedKeyBaja,
                    displaySize: CGSize(width: 180, height: 130),
                    content: { image in image.resizable().scaledToFill() },
                    placeholder: {
                        AdaptiveShimmerView(cornerRadius: 14)
                    },
                    failure: {
                        AdaptiveShimmerView(cornerRadius: 14)
                    }
                )
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    favoritesManager.toggleFavorite(productId: product.id)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                        favoritePulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        favoritePulse = false
                    }
                } label: {
                    let isFavorite = favoritesManager.isFavorite(productId: product.id)
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isFavorite ? .red : .gray)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.cardBackground(colorScheme))
                                .shadow(color: .black.opacity(0.1), radius: 4)
                        )
                }
                .scaleEffect(favoritePulse ? 1.15 : 1.0)
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(2)
                    .frame(height: 40, alignment: .top)

                HStack(spacing: 4) {
                    if let avatarUrl = product.branchAvatarUrl, !avatarUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: avatarUrl),
                            cacheKey: product.cachedBranchAvatarKey,
                            content: { image in image.resizable().scaledToFill() },
                            placeholder: { Circle().fill(Color.gray.opacity(0.2)) }
                        )
                        .frame(width: 14, height: 14)
                        .clipShape(Circle())
                    }

                    Text(product.businessName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(height: 16)

                Text(product.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 7, x: 0, y: 4)
        )
    }
}

// MARK: - Tutorial Feed Card
struct TutorialFeedCard: View {
    let tutorial: Tutorial
    let accentColor: Color
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var downloadManager = TutorialDownloadManager.shared
    private let cardWidth: CGFloat = 240
    private let cardHeight: CGFloat = 135

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background image
                CachedAsyncImage(
                    url: URL(string: tutorial.thumbnailUrl),
                    cacheKey: "tutorial_\(tutorial.id)",
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                )
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

                // Gradient overlay - darker for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.75),
                        Color.clear,
                    ]),
                    startPoint: .bottom,
                    endPoint: .center
                )

                // Play button - center

                ZStack {
                    Circle()
                        .modifier(CircleGlassEffectModifier())
                        .frame(width: 48, height: 48)

                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(accentColor)
                        .offset(x: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Duration badge - top right
                VStack {
                    HStack {
                        Spacer()
                        Text(tutorial.duration)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .padding([.trailing, .top], 10)
                    }
                    Spacer()
                }

                // Info overlay - bottom with text
                VStack(alignment: .leading, spacing: 4) {
                    if let category = tutorial.category {
                        Text(category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.9))
                            )
                    }

                    Text(tutorial.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
            }
            .frame(width: cardWidth, height: cardHeight)
            .overlay(alignment: .topLeading) {
                downloadStateBadge
                    .padding(10)
            }
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var downloadStateBadge: some View {
        switch downloadManager.status(for: tutorial.id) {
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())

        case .downloading(let progress):
            HStack(spacing: 6) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(width: 16, height: 16)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.65), in: Capsule())

        default:
            EmptyView()
        }
    }
}

// MARK: - Tutorial Video Player View
struct TutorialVideoPlayerView: View {
    let tutorial: Tutorial
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                ZStack {
                    Rectangle().fill(Color.black)
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text(tutorial.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)

                VStack(alignment: .leading, spacing: 12) {
                    Text(tutorial.title)
                        .font(.system(size: 20, weight: .bold))
                    Text(tutorial.description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "clock").foregroundColor(accentColor)
                        Text(tutorial.duration)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Promotion Card
struct PromotionCard: View {
    let promotion: Promotion
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    private var typeColor: Color {
        Color(hex: promotion.type.color) ?? .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(
                    url: URL(string: promotion.imageUrl),
                    cacheKey: "promo_\(promotion.id)",
                    content: { image in
                        image.resizable().scaledToFill()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView().scaleEffect(0.8))
                    },
                    failure: {
                        Rectangle()
                            .fill(typeColor.opacity(0.3))
                            .overlay(
                                Image(systemName: promotion.type.icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(typeColor)
                            )
                    }
                )
                .frame(width: 200, height: 120)
                .clipped()

                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: promotion.type.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(promotion.type.label)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(typeColor)
                )
                .padding(8)

                // Discount badge
                if let discount = promotion.formattedDiscount {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(discount)
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                )
                                .padding(8)
                        }
                    }
                }
            }
            .frame(width: 200, height: 120)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(promotion.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(1)

                Text(promotion.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .top)

                HStack {
                    // Price info
                    if let discounted = promotion.formattedDiscountedPrice {
                        HStack(spacing: 4) {
                            if let original = promotion.formattedOriginalPrice {
                                Text(original)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                            }
                            Text(discounted)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                    }

                    Spacer()

                    // Time remaining
                    if let time = promotion.timeRemaining {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(time)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(promotion.type == .flash ? .red : .secondary)
                    }
                }

                // Store name
                if let storeName = promotion.storeName {
                    Text(storeName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 7, x: 0, y: 4)
        )
    }
}

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

private struct CircleGlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive())
        } else {
            content
        }
    }
}

// MARK: - Login Prompt Card
struct LoginPromptCard: View {
    let accentColor: Color
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.25),
                                accentColor.opacity(0.08),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mejores recomendaciones para ti")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Inicia sesión y descubre más productos personalizados.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme).opacity(0.65))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onTap) {
                Text("Entrar")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .modifier(LoginPromptButtonModifier(accentColor: accentColor))
        }
        .padding(14)
        .modifier(LoginPromptCardGlassModifier(colorScheme: colorScheme))
    }
}

private struct LoginPromptButtonModifier: ViewModifier {
    let accentColor: Color

    private var tintGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor,
                accentColor.opacity(0.85),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(tintGradient)
        } else {
            content
                .background(Capsule().fill(tintGradient))
                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

private struct LoginPromptCardGlassModifier: ViewModifier {
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, x: 0, y: 4)
                )
        }
    }
}

// MARK: - Reorder Item Card
struct ReorderItemCard: View {
    let item: ReorderItem
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: imageUrl),
                        cacheKey: "reorder_\(item.productId)",
                        displaySize: CGSize(width: 120, height: 90),
                        content: { image in image.resizable().scaledToFill() },
                        placeholder: { AdaptiveShimmerView(cornerRadius: 12) },
                        failure: { AdaptiveShimmerView(cornerRadius: 12) }
                    )
                    .frame(width: 120, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 120, height: 90)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.4))
                        )
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(2)
                    .frame(width: 120, height: 34, alignment: .topLeading)

                Text(item.branchName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
            }
        }
        .frame(width: 120)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                    radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Pide de Nuevo Inline Card

struct PideDeNuevoInlineCard: View {
    let item: ReorderItem
    let accentColor: Color
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                    CachedAsyncImage(
                        url: URL(string: imageUrl),
                        cacheKey: "reorder_inline_\(item.productId)",
                        displaySize: CGSize(width: 64, height: 64),
                        content: { image in image.resizable().scaledToFill() },
                        placeholder: { AdaptiveShimmerView(cornerRadius: 12) },
                        failure: { AdaptiveShimmerView(cornerRadius: 12) }
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.4))
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("¿Lo pides de nuevo?")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                        .lineLimit(1)
                    Text(item.branchName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accentColor)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground(colorScheme))
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.2 : 0.06),
                        radius: 6, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Store Card

struct FeaturedStoreCard: View {
    let store: FeedStore
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationLink(destination: StoreDetailView(storeId: store.id)) {
            ZStack(alignment: .bottomLeading) {
                coverImage
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                LinearGradient(
                    colors: [.black.opacity(0.65), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(alignment: .bottom, spacing: 12) {
                    if let avatarUrl = store.preferredAvatarSmallUrl {
                        CachedAsyncImage(
                            url: URL(string: avatarUrl),
                            cacheKey: "featured_store_avatar_\(store.id)",
                            content: { image in image.resizable().scaledToFill() },
                            placeholder: { Circle().fill(Color.white.opacity(0.3)) }
                        )
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let address = store.address, !address.isEmpty {
                            Text(address)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Text("Ver tienda")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(accentColor))
                }
                .padding(14)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = store.preferredCoverFastUrl {
            CachedAsyncImage(
                url: URL(string: coverUrl),
                cacheKey: "featured_store_cover_\(store.id)",
                content: { image in image.resizable().scaledToFill() },
                placeholder: { AdaptiveShimmerView(cornerRadius: 16) },
                failure: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(0.2))
                        .overlay(
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 40))
                                .foregroundColor(accentColor.opacity(0.5))
                        )
                }
            )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.2))
                .overlay(
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor.opacity(0.5))
                )
        }
    }
}

// MARK: - Explorar Product Card

struct ExplorarProductCard: View {
    let product: FeedProduct
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedAsyncImage(
                url: URL(string: product.imageUrlBaja),
                cacheKey: "explorar_\(product.id)",
                content: { image in image.resizable().scaledToFill() },
                placeholder: { AdaptiveShimmerView(cornerRadius: 0) },
                failure: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.35))
                        )
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 0) {
                    Text(product.formattedPrice)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accentColor)
                    Spacer()
                }

                if let branchName = product.branchName.isEmpty ? nil : product.branchName {
                    Text(branchName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ProductFeedView()
}
