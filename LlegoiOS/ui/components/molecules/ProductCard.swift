import SwiftUI


struct Product: Identifiable, Hashable {
    let id: String // ID real de GraphQL
    let name: String
    let shop: String
    let weight: String
    let price: String
    let imageUrl: String
}

struct ImagePositionKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct ProductCard: View {
    let product: Product
    @Binding var count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil
    var onProductTap: (() -> Void)? = nil

    @State private var imagePosition: CGPoint = .zero

    // CartManager singleton para añadir al carrito globalmente
    private let cartManager = CartManager.shared

    var body: some View {
        Button(action: {
            onProductTap?()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Image section - Más compacta
                CachedAsyncImage(
                    url: URL(string: product.imageUrl),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    placeholder: {
                        ZStack {
                            Color.gray.opacity(0.06)
                            ProgressView()
                                .tint(.llegoPrimary)
                        }
                    }
                )
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(10)
                .background(
                    GeometryReader { imageGeometry in
                        Color.clear.preference(
                            key: ImagePositionKey.self,
                            value: imageGeometry.frame(in: .global).center
                        )
                    }
                )

                // Product info section - Más compacto
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .frame(height: 36, alignment: .topLeading)

                    Text(product.shop)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Price and cart section - Más compacto
                HStack(alignment: .center, spacing: 6) {
                    Text(product.price)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.llegoPrimary)

                    Spacer()

                    // Add to cart button - Más pequeño
                    if count == 0 {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                cartManager.addToCart(productId: product.id, quantity: 1)
                                onIncrement()
                                onAddToCartAnimation?(product.imageUrl, imagePosition)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.llegoPrimary)
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Counter - Más compacto
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    let currentQty = cartManager.getQuantity(for: product.id)
                                    cartManager.updateQuantity(productId: product.id, quantity: currentQty - 1)
                                    onDecrement()
                                }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.llegoPrimary)
                                    .frame(width: 26, height: 26)
                                    .background(
                                        Circle()
                                            .fill(Color.llegoAccent.opacity(0.25))
                                    )
                            }
                            .buttonStyle(.plain)

                            Text("\(count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(minWidth: 20)

                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    cartManager.addToCart(productId: product.id, quantity: 1)
                                    onIncrement()
                                    onAddToCartAnimation?(product.imageUrl, imagePosition)
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(
                                        Circle()
                                            .fill(Color.llegoPrimary)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(10)
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.06), lineWidth: 1)
        )
        .onPreferenceChange(ImagePositionKey.self) { position in
            imagePosition = position
        }
    }
}
