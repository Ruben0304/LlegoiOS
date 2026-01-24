import SwiftUI
import MapKit

// MARK: - 3D Flip Card Wrapper
struct StoreProductsCard: View {
    let store: StoreWithCoordinates
    let products: [ProductGraphQL]
    let isLoadingProducts: Bool
    let onStoreTap: (ExtractedGradient?) -> Void
    let onProductTap: (ProductGraphQL, ExtractedGradient?) -> Void

    let onFavoriteTap: (ProductGraphQL) -> Void
    var onBodyTap: (() -> Void)? = nil
    var onGradientExtracted: ((ExtractedGradient) -> Void)? = nil

    @State private var isFlipped = false
    @State private var flipDegrees: Double = 0
    @State private var cardScale: CGFloat = 1.0
    @State private var shadowOffset: CGFloat = 8
    @State private var perspectiveTilt: Double = 0

    var body: some View {
        ZStack {
            // Back side (Map)
            StoreProductsCardBack(
                store: store,
                isFlipped: isFlipped,
                onFlipBack: { performFlip() }
            )
            .rotation3DEffect(
                .degrees(flipDegrees + 180),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.3
            )
            .opacity(isFlipped ? 1 : 0)

            // Front side (Products)
            StoreProductsCardFront(
                store: store,
                products: products,
                isLoadingProducts: isLoadingProducts,
                onStoreTap: onStoreTap,
                onProductTap: onProductTap,
                onFavoriteTap: onFavoriteTap,
                onBodyTap: onBodyTap,
                onFlip: { performFlip() },
                onGradientExtracted: onGradientExtracted
            )
            .rotation3DEffect(
                .degrees(flipDegrees),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.3
            )
            .opacity(isFlipped ? 0 : 1)
        }
        // 3D Depth effect - Multiple layered shadows
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.04))
                .offset(x: 0, y: shadowOffset + 4)
                .blur(radius: 20)
        )
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.08))
                .offset(x: 0, y: shadowOffset + 2)
                .blur(radius: 12)
        )
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.12))
                .offset(x: 0, y: shadowOffset)
                .blur(radius: 6)
        )
        .scaleEffect(cardScale)
        // Subtle 3D tilt based on flip state
        .rotation3DEffect(
            .degrees(perspectiveTilt),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
    }

    private func performFlip() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()

        // Animate the flip with 3D depth effects
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardScale = 0.95
            shadowOffset = 4
            perspectiveTilt = isFlipped ? 3 : -3
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.05)) {
            flipDegrees += 180
            isFlipped.toggle()
        }

        // Reset scale and shadow
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35)) {
            cardScale = 1.0
            shadowOffset = 8
            perspectiveTilt = 0
        }
    }
}

// MARK: - Front Side (Original Card with Products)
private struct StoreProductsCardFront: View {
    let store: StoreWithCoordinates
    let products: [ProductGraphQL]
    let isLoadingProducts: Bool
    let onStoreTap: (ExtractedGradient?) -> Void
    let onProductTap: (ProductGraphQL, ExtractedGradient?) -> Void

    let onFavoriteTap: (ProductGraphQL) -> Void
    var onBodyTap: (() -> Void)? = nil
    let onFlip: () -> Void
    var onGradientExtracted: ((ExtractedGradient) -> Void)? = nil

    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var storeGradient: ExtractedGradient = .placeholder

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            storeHeader
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)

            // Products Grid
            productsContent
        }
        .background(
            ZStack {
                // Base gradient from store logo
                storeGradient.linearGradient

                // Smooth dark overlay for header legibility
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.7), location: 0),
                        .init(color: Color.black.opacity(0.5), location: 0.15),
                        .init(color: Color.black.opacity(0.3), location: 0.25),
                        .init(color: Color.black.opacity(0.1), location: 0.35),
                        .init(color: Color.clear, location: 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 3D lighting effect - top highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            // 3D Edge lighting effect
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.4), location: 0),
                            .init(color: Color.white.opacity(0.15), location: 0.3),
                            .init(color: storeGradient.primaryColor.opacity(0.2), location: 0.5),
                            .init(color: storeGradient.secondaryColor.opacity(0.3), location: 0.7),
                            .init(color: Color.black.opacity(0.1), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // Inner shadow for depth
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
                .blur(radius: 1)
                .offset(x: 0, y: 1)
                .mask(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.black, Color.clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                )
        )

        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if storeGradient == .placeholder {
                    extractFallbackGradient()
                }
            }
        }
    }

    // MARK: - Products Content
    @ViewBuilder
    private var productsContent: some View {
        if isLoadingProducts {
            productsSkeletonGrid
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        } else if products.isEmpty {
            emptyProductsView
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(products.prefix(4)) { product in
                    ProductFullCoverCard(
                        product: product,
                        isFavorite: favoritesManager.isFavorite(productId: product.id),
                        onTap: { },
                        onFavoriteTap: { onFavoriteTap(product) }
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }

        if let promo = store.promo {
            promoBanner(promo)
        }
    }

    private func extractFallbackGradient() {
        guard storeGradient == .placeholder else { return }
        ExtractedGradient.fromAsset(named: "generic_cover") { gradient in
            DispatchQueue.main.async {
                if self.storeGradient == .placeholder {
                    self.storeGradient = gradient
                    self.onGradientExtracted?(gradient)
                }
            }
        }
    }

    // MARK: - Store Header
    private var storeHeader: some View {
        HStack(spacing: 10) {
            // Logo with gradient extraction
            GradientAsyncImage(
                url: URL(string: store.logoUrl),
                cacheKey: "store_logo_\(store.id)",
                extractedGradient: $storeGradient,
                fallbackGradient: .fromAsset(named: "generic_cover")
            ) { image, extractedGradient in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                         if storeGradient != .placeholder {
                             onGradientExtracted?(storeGradient)
                         } else {
                             // Retry extraction if needed
                             // Trigger a state change to force re-evaluation if view recycles
                         }
                    }
                    .onChange(of: extractedGradient) { newGradient in
                        withAnimation(.easeOut(duration: 0.5)) {
                            onGradientExtracted?(newGradient)
                        }
                    }
            } placeholder: {
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        extractFallbackGradient()
                    }
            } failure: { _, _ in
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        extractFallbackGradient()
                    }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                storeGradient.primaryColor.opacity(0.8), // Increased opacity for "HDR" feel
                                storeGradient.secondaryColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: storeGradient.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4) // Stronger shadow
            .id("logo_\(store.id)") // Force refresh when store changes

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let address = store.address {
                        Text(address)
                            .lineLimit(1)
                    }
                    Text("• \(store.etaMinutes) min")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
            }

            Spacer()

            // Flip Button (Custom Tap Gesture)
            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 36, height: 36)
                .foregroundColor(.white)
                .glassEffect(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    onFlip()
                }

            // Options Button (Custom Tap Gesture)
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 36, height: 36)
                .foregroundColor(.white)
                .glassEffect(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    onStoreTap(storeGradient)
                }
        }
    }

    // MARK: - Products Skeleton
    private var productsSkeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 140)
                    .shimmer()
            }
        }
    }

    // MARK: - Empty Products View
    private var emptyProductsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bag")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.gray.opacity(0.5))

            Text("Sin productos disponibles")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Promo Banner
    private func promoBanner(_ promo: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(promo)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("Ahorra 30 US$")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(storeGradient.primaryColor)
                        )

                    Text("en pedidos +80 US$")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(storeGradient.primaryColor.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(storeGradient.primaryColor)
                )
        }
        .padding(12)
        .background(storeGradient.primaryColor.opacity(0.05))
    }
}

// MARK: - Store Annotation for Map
private struct StoreAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let store: StoreWithCoordinates
}

// MARK: - Back Side (Full Map View)
private struct StoreProductsCardBack: View {
    let store: StoreWithCoordinates
    let isFlipped: Bool
    let onFlipBack: () -> Void

    @State private var mapRegion: MKCoordinateRegion
    @State private var isPulsing = false

    // Default Havana coordinates as fallback
    private static let defaultHavanaCoordinate = CLLocationCoordinate2D(
        latitude: 23.1136,
        longitude: -82.3666
    )

    init(store: StoreWithCoordinates, isFlipped: Bool, onFlipBack: @escaping () -> Void) {
        self.store = store
        self.isFlipped = isFlipped
        self.onFlipBack = onFlipBack

        // Use store coordinate if valid, otherwise fallback to Havana
        let coordinate = Self.isValidCoordinate(store.coordinate)
            ? store.coordinate
            : Self.defaultHavanaCoordinate

        self._mapRegion = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        ))
    }

    private static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude != 0 && coordinate.longitude != 0 &&
        coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
        coordinate.longitude >= -180 && coordinate.longitude <= 180
    }

    private var effectiveCoordinate: CLLocationCoordinate2D {
        Self.isValidCoordinate(store.coordinate)
            ? store.coordinate
            : Self.defaultHavanaCoordinate
    }

    var body: some View {
        ZStack {
            // Full screen map
            Map(coordinateRegion: $mapRegion, annotationItems: [StoreAnnotation(id: store.id, coordinate: effectiveCoordinate, store: store)]) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    StoreMapPin(store: annotation.store, isPulsing: isPulsing)
                }
            }
            .disabled(true)

            // Flip button floating on top
            VStack {
                HStack {
                    Spacer()

                    Button(action: onFlipBack) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white)
                    }
                    .glassEffect(.regular.interactive())
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .buttonStyle(.borderless)
                }
                .padding(12)

                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Store Map Pin (Same style as FullScreenMapView)
private struct StoreMapPin: View {
    let store: StoreWithCoordinates
    let isPulsing: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Pulsing ring
            ZStack {
                // Outer pulse
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPulsing ? 1.3 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)

                // Inner pulse
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.2 : 0.5)

                // Pin head with logo
                ZStack {
                    // Gradient border
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.llegoPrimary,
                                    Color.llegoPrimary.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    // Logo image with cache
                    CachedAsyncImage(
                        url: URL(string: store.logoUrl),
                        cacheKey: "store_logo_pin_\(store.id)",
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 42, height: 42)
                                .clipShape(Circle())
                        },
                        placeholder: {
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            .frame(width: 42, height: 42)
                            .clipShape(Circle())
                        },
                        failure: {
                            Image("generic_logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 42, height: 42)
                                .clipShape(Circle())
                        }
                    )
                }
                .shadow(color: Color.llegoPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
            }

            // Pin point
            StoreMapPinTriangle()
                .fill(Color.llegoPrimary)
                .frame(width: 16, height: 12)
                .offset(y: -1)

            // Ground shadow
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 8)
                .offset(y: 4)
        }
    }
}

// MARK: - Pin Triangle Shape
private struct StoreMapPinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Product Full Cover Card (Image fills entire card)
struct ProductFullCoverCard: View {
    let product: ProductGraphQL
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // White background for transparent images
                Color.white

                // Product Image - Full Cover with Cache
                CachedAsyncImage(
                    url: URL(string: product.imageUrl),
                    cacheKey: "shop_product_\(product.id)", // Cache key específica para productos de tienda
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                                .scaleEffect(1.2)
                        }
                    },
                    failure: {
                        Image("generic_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .opacity(0.4)
                    }
                )
                .frame(height: 140)
                .clipped()

                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.4)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Price Badge (Top Left) & Favorite (Bottom Right)
                VStack {
                    HStack {
                        Text(product.formattedPrice)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                            )

                        Spacer()
                    }

                    Spacer()

                    HStack {
                        Spacer()

                        Button(action: onFavoriteTap) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isFavorite ? .red : .white)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(8)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StoreWithCoordinates Extension for Promo
extension StoreWithCoordinates {
    var promo: String? {
        // TODO: Add promo field from backend when available
        return nil
    }
}
