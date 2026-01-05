import SwiftUI
import UIKit


struct Product: Identifiable, Hashable {
    let id: String // ID real de GraphQL
    let name: String
    let shop: String
    let weight: String
    let price: String
    let imageUrl: String
}

struct ProductCard: View {
    let product: Product
    @Binding var count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil
    var onProductTap: (() -> Void)? = nil

    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var favoritePulse = false
    
    private static let titleUIFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    private static let titleReservedHeight: CGFloat = ceil(titleUIFont.lineHeight * 2)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContainer

            favoriteButton
                .padding(.top, 16)
                .padding(.trailing, 16)
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
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 26))
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .compositingGroup()
            .tint(.white)
        } else {
            // Let an outer container (e.g. NavigationLink) handle the tap.
            cardContent
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private var cardContent: some View {
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

                Text(product.shop)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Text(product.price)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
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
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
