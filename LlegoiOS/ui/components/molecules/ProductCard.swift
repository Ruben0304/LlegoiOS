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
            HStack(spacing: 14) {
                // Image section - Cuadrada a la izquierda
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
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .background(
                    GeometryReader { imageGeometry in
                        Color.clear.preference(
                            key: ImagePositionKey.self,
                            value: imageGeometry.frame(in: .global).center
                        )
                    }
                )

                // Product info section - A la derecha
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    Text(product.shop)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Price and cart section
                    HStack(alignment: .center, spacing: 8) {
                        Text(product.price)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.llegoPrimary)

                        Spacer()

                        // Add to cart button
                        if count == 0 {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    cartManager.addToCart(productId: product.id, quantity: 1)
                                    onIncrement()
                                    onAddToCartAnimation?(product.imageUrl, imagePosition)
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.llegoPrimary)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Counter
                            HStack(spacing: 10) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                        let currentQty = cartManager.getQuantity(for: product.id)
                                        cartManager.updateQuantity(productId: product.id, quantity: currentQty - 1)
                                        onDecrement()
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.llegoPrimary)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .fill(Color.llegoAccent.opacity(0.25))
                                        )
                                }
                                .buttonStyle(.plain)

                                Text("\(count)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 24)

                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                        cartManager.addToCart(productId: product.id, quantity: 1)
                                        onIncrement()
                                        onAddToCartAnimation?(product.imageUrl, imagePosition)
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
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
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .frame(height: 128)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onPreferenceChange(ImagePositionKey.self) { position in
            imagePosition = position
        }
    }
}
