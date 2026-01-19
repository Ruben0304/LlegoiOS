import SwiftUI
import AVKit

struct ProductFeedView: View {
    @StateObject private var viewModel = ProductFeedViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var cartManager = CartManager.shared
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var showFavoritesSheet = false
    @State private var showCartSheet = false
    @State private var selectedTutorial: Tutorial? = nil
    @State private var showVideoPlayer = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo gradiente sutil que se sincroniza con HomeView
                feedGradientBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)

                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.isLoading {
                        loadingState
                    } else if case .error(let message) = viewModel.state {
                        errorState(message: message)
                    } else if viewModel.featuredProducts.isEmpty && viewModel.recentProducts.isEmpty {
                        emptyState
                    } else {
                        feedContent
                    }
                }
            }
            .toolbar {
                // "Para ti" al lado izquierdo
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Para ti")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnBackground(colorScheme))
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
                
                // Botón de favoritos
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFavoritesSheet = true }) {
                        Image(systemName: "heart")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .badge(favoritesManager.favoriteItemCount)
                    .accessibilityLabel("Favoritos")
                }

                // Spacer entre favoritos y carrito
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)

                // Botón de carrito
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCartSheet = true }) {
                        Image(systemName: "cart")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .badge(cartManager.cartItemCount)
                    .accessibilityLabel("Carrito")
                }
            }
            .sheet(isPresented: $showCartSheet) {
                NavigationView { CartView() }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFavoritesSheet) {
                NavigationView { FavoritesView() }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let tutorial = selectedTutorial {
                    TutorialVideoPlayerView(tutorial: tutorial, accentColor: gradientManager.currentAccentColor)
                }
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
                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.95), location: 1.0)
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

                if !viewModel.filteredFeaturedProducts.isEmpty { featuredProductsSection }
                if !viewModel.filteredPopularProducts.isEmpty { popularProductsSection }
                if !viewModel.stores.isEmpty { storesSection }

                if viewModel.showTutorials && !viewModel.tutorials.isEmpty {
                    tutorialsSection
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                }

                if !viewModel.promotions.isEmpty { promotionsSection }

                if !viewModel.filteredRecentProducts.isEmpty { recentProductsSection }

                if viewModel.isLoadingMore {
                    ProgressView().tint(gradientManager.currentAccentColor).padding(.vertical, 20)
                }
            }
        }
        .refreshable { await refreshFeed() }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories) { category in
                    let isSelected = category.isAll
                        ? viewModel.selectedCategory == nil
                        : viewModel.selectedCategory == category.name

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
    
    // MARK: - Promotions Section
    private var promotionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("Ofertas y Promociones")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                }
                Spacer()
                Text("Ver todo")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.promotions) { promotion in
                        PromotionCard(promotion: promotion, accentColor: gradientManager.currentAccentColor)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
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
                        TutorialFeedCard(tutorial: tutorial) {
                            selectedTutorial = tutorial
                            showVideoPlayer = true
                        }
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Stores Section
    private var storesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lo mejor de Llego")
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
                    ForEach(viewModel.stores) { store in
                        NavigationLink(destination: StoreDetailView(storeId: store.id)) {
                            StoreCircleCard(store: store, accentColor: gradientManager.currentAccentColor)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Featured Products Section
    private var featuredProductsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.filteredFeaturedProducts) { product in
                        NavigationLink(destination: ProductDetailView(productId: product.id)) {
                            FeaturedProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Popular Products Section
    private var popularProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Populares cerca de ti")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.filteredPopularProducts) { product in
                        NavigationLink(destination: ProductDetailView(productId: product.id)) {
                            SmallProductCard(product: product, accentColor: gradientManager.currentAccentColor)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Recent Products Section
    private var recentProductsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recomendaciones para ti")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .padding(.horizontal, 20)
            
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 16
            ) {
                ForEach(viewModel.filteredRecentProducts) { product in
                    NavigationLink(destination: ProductDetailView(productId: product.id)) {
                        CompactProductCard(product: product, accentColor: gradientManager.currentAccentColor)
                            .onAppear { viewModel.loadMoreIfNeeded(currentItem: product) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
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
        VStack(spacing: 20) {
            ProgressView().controlSize(.large).tint(gradientManager.currentAccentColor)
            Text("Cargando...").font(.system(size: 16, weight: .medium)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
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
            Button("Reintentar") { viewModel.loadFeed() }
                .frame(height: 50)
                .frame(maxWidth: 200)
                .buttonStyle(.glassProminent)
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
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 10, x: 0, y: 5)

                if let avatarUrl = store.avatarUrl, !avatarUrl.isEmpty {
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

// MARK: - Featured Product Card
struct FeaturedProductCard: View {
    let product: FeedProduct
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
                cacheKey: "featured_\(product.id)",
                content: { image in
                    image.resizable().scaledToFill()
                },
                placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                },
                failure: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            )
            .frame(width: 280, height: 350)
            .clipped()
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            VStack(alignment: .leading, spacing: 6) {
                if let avatarUrl = product.branchAvatarUrl, !avatarUrl.isEmpty {
                    HStack(spacing: 6) {
                        CachedAsyncImage(
                            url: URL(string: avatarUrl),
                            cacheKey: "branch_\(product.branchId)",
                            content: { image in image.resizable().scaledToFill() },
                            placeholder: { Circle().fill(Color.white.opacity(0.3)) }
                        )
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

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
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Small Product Card
struct SmallProductCard: View {
    let product: FeedProduct
    let accentColor: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CachedAsyncImage(
                url: URL(string: product.imageUrl),
                cacheKey: "small_\(product.id)",
                content: { image in image.resizable().scaledToFill() },
                placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView().scaleEffect(0.7))
                },
                failure: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            )
            .frame(width: 140, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))

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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
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
                    url: URL(string: product.imageUrl),
                    cacheKey: "compact_\(product.id)",
                    content: { image in image.resizable().scaledToFill() },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .overlay(ProgressView().scaleEffect(0.8))
                    },
                    failure: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.4))
                            )
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
                            cacheKey: "branch_small_\(product.branchId)",
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Tutorial Feed Card
struct TutorialFeedCard: View {
    let tutorial: Tutorial
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                CachedAsyncImage(
                    url: URL(string: tutorial.thumbnailUrl),
                    cacheKey: "tutorial_\(tutorial.id)",
                    content: { image in image.resizable().scaledToFill() },
                    placeholder: { Rectangle().fill(Color.gray.opacity(0.2)) }
                )
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    )

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(tutorial.duration)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.7)))
                            .padding(8)
                    }
                }
            }
            .frame(height: 110)

            Text(tutorial.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .lineLimit(2)
                .frame(height: 36, alignment: .top)

            if let category = tutorial.category {
                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 180)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(colorScheme))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        )
        .onTapGesture { onTap() }
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
                .aspectRatio(16/9, contentMode: .fit)
                
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
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    ProductFeedView()
}
