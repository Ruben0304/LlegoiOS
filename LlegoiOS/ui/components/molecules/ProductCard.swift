import SwiftUI
import UIKit


struct Product: Identifiable, Hashable, Codable, Sendable {
    let id: String // ID real de GraphQL
    let name: String
    let shop: String
    let shopLogoUrl: String
    let weight: String
    let price: String
    let imageUrl: String
    
    // Backward compatibility initializer
    init(id: String, name: String, shop: String, shopLogoUrl: String = "", weight: String, price: String, imageUrl: String) {
        self.id = id
        self.name = name
        self.shop = shop
        self.shopLogoUrl = shopLogoUrl
        self.weight = weight
        self.price = price
        self.imageUrl = imageUrl
    }
}

struct ProductCard: View {
    let product: Product
    @Binding var count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil
    var onProductTap: (() -> Void)? = nil
    var showsFavoriteButton: Bool = true
    var showAddToCartButton: Bool = false
    var onQuickAddToCart: (() -> Void)? = nil

    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var favoritePulse = false
    @State private var quickAddPulse = false
    @State private var isPressed = false
    
    private static let titleUIFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    private static let titleReservedHeight: CGFloat = ceil(titleUIFont.lineHeight * 2)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContainer

            if showsFavoriteButton {
                favoriteButton
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            } else if showAddToCartButton {
                addToCartButton
                    .padding(.top, 16)
                    .padding(.trailing, 16)
            }
        }
    }

    @ViewBuilder
    private var cardContainer: some View {
        if let onProductTap {
            Button(action: {
                onProductTap()
            }) {
                cardContent
            }
            .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
            .buttonBorderShape(.roundedRectangle(radius: 26))
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .compositingGroup()
        } else {
            // Let an outer container (e.g. NavigationLink) handle the tap.
            cardContent
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private var cardContent: some View {
        ZStack {
            // HDR Glow cuando está presionado
            if isPressed {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        HDRGlowView(
                            color: .llegoPrimary,
                            intensity: 1.5,
                            radius: 0.5
                        )
                        .blur(radius: 10)
                    )
                    .transition(.opacity)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                imageSection

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: Self.titleReservedHeight, alignment: .topLeading)

                    HStack(spacing: 4) {
                        // Shop logo circular
                        if !product.shopLogoUrl.isEmpty {
                            CachedAsyncImage(
                                url: URL(string: product.shopLogoUrl),
                                cacheKey: "shop_logo_\(product.shop)",
                                content: { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                },
                                placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                },
                                failure: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                            )
                            .frame(width: 14, height: 14)
                            .clipShape(Circle())
                        }
                        
                        Text(product.shop)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(product.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(26)
        }
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }

    private var imageSection: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.clear)
            .overlay(
                CachedAsyncImage(
                    url: URL(string: product.imageUrl),
                    cacheKey: "product_\(product.id)", // Cache key específica para productos
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    placeholder: {
                        ZStack {
                            Color(red: 240/255, green: 242/255, blue: 246/255)
                            ProgressView()
                                .tint(.llegoPrimary)
                        }
                    },
                    failure: {
                        ZStack {
                            Color(red: 240/255, green: 242/255, blue: 246/255)
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 150)
    }

    private var favoriteButton: some View {
        let isFavorite = favoritesManager.isFavorite(productId: product.id)

        return Button {
            favoritesManager.toggleFavorite(productId: product.id)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                favoritePulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                favoritePulse = false
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isFavorite ? Color.red : Color.gray)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
        .scaleEffect(favoritePulse ? 1.15 : 1.0)
        .buttonStyle(.plain)
        .padding(8)
    }

    private var addToCartButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                quickAddPulse = true
            }
            onQuickAddToCart?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    quickAddPulse = false
                }
            }
        } label: {
            Image(systemName: quickAddPulse ? "checkmark.circle.fill" : "cart.badge.plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(gradientManager.currentAccentColor)
                .frame(width: 38, height: 38)
                .scaleEffect(quickAddPulse ? 1.12 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.6), value: quickAddPulse)
        }
        .buttonStyle(.glass)
        .padding(8)
    }
}

private struct OptionalTapModifier: ViewModifier {
    let onTap: (() -> Void)?

    func body(content: Content) -> some View {
        if let onTap = onTap {
            content.onTapGesture(perform: onTap)
        } else {
            content
        }
    }
}

// ButtonStyle personalizado para detectar pressed state
private struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}
