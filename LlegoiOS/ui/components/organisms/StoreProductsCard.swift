import SwiftUI

// MARK: - Store Products Card (Full Store Card with Products Grid)
struct StoreProductsCard: View {
    let store: StoreWithCoordinates
    let products: [ShopProductGraphQL]
    let isLoadingProducts: Bool
    let onStoreTap: () -> Void
    let onProductTap: (ShopProductGraphQL) -> Void
    let onFavoriteTap: (ShopProductGraphQL) -> Void

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

                // Smooth dark overlay for header legibility (only on background)
                LinearGradient(
                    stops: [
                        .init(color: Color.black.opacity(0.55), location: 0),
                        .init(color: Color.black.opacity(0.4), location: 0.15),
                        .init(color: Color.black.opacity(0.2), location: 0.25),
                        .init(color: Color.black.opacity(0.05), location: 0.35),
                        .init(color: Color.clear, location: 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            storeGradient.primaryColor.opacity(0.3),
                            storeGradient.secondaryColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: storeGradient.primaryColor.opacity(0.15), radius: 16, x: 0, y: 8)
        .onAppear {
            // If gradient is still placeholder after a moment, use fallback
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
        // Products Grid
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
                    ForEach(products) { product in
                        ProductFullCoverCard(
                            product: product,
                            isFavorite: favoritesManager.isFavorite(productId: product.id),
                            onTap: { onProductTap(product) },
                            onFavoriteTap: { onFavoriteTap(product) }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }

        // Promo Banner (optional)
        if let promo = store.promo {
            promoBanner(promo)
        }
    }

    // MARK: - Extract Fallback Gradient
    private func extractFallbackGradient() {
        guard storeGradient == .placeholder else { return }
        ExtractedGradient.fromAsset(named: "generic_cover") { gradient in
            DispatchQueue.main.async {
                if self.storeGradient == .placeholder {
                    self.storeGradient = gradient
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
            ) { image, _ in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        // Extract gradient from generic cover when no logo
                        extractFallbackGradient()
                    }
            } failure: { _, _ in
                Image("generic_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        // Extract gradient from generic cover on failure
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
                                storeGradient.primaryColor.opacity(0.6),
                                storeGradient.secondaryColor.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: storeGradient.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)

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

            // Options Button
            Button(action: onStoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.white)
            }
            .glassEffect(.clear)
        }
    }

    // MARK: - Products Skeleton
    private var productsSkeletonGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<6, id: \.self) { _ in
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

// MARK: - Product Full Cover Card (Image fills entire card)
struct ProductFullCoverCard: View {
    let product: ShopProductGraphQL
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavoriteTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // White background for transparent images
                Color.white

                // Product Image - Full Cover
                AsyncImage(url: URL(string: product.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ProgressView()
                            .tint(.gray)
                    case .failure:
                        Image("generic_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .opacity(0.4)
                    @unknown default:
                        Color.white
                    }
                }
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
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - StoreWithCoordinates Extension for Promo
extension StoreWithCoordinates {
    var promo: String? {
        // TODO: Add promo field from backend when available
        return nil
    }
}
