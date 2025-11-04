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
        VStack(alignment: .leading, spacing: 0) {
            // Image section with rating badge (tappable para navegar)
            ZStack(alignment: .topLeading) {
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
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(
                    GeometryReader { imageGeometry in
                        Color.clear.preference(
                            key: ImagePositionKey.self,
                            value: imageGeometry.frame(in: .global).center
                        )
                    }
                )

                // Rating badge (floating)
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)

                    Text("4.8")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                )
                .glassEffect(.regular)
                .padding(10)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onProductTap?()
            }

            // Product info section
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(height: 40, alignment: .top)

                Text(product.shop)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                // Price and cart section
                HStack(alignment: .center) {
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
                    } else {
                        // Counter
                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    let currentQty = cartManager.getQuantity(for: product.id)
                                    cartManager.updateQuantity(productId: product.id, quantity: currentQty - 1)
                                    onDecrement()
                                }
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.llegoPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.llegoAccent.opacity(0.25))
                                    )
                            }

                            Text("\(count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(minWidth: 24)

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
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(Color.llegoPrimary)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.08), lineWidth: 1)
        )
        .onPreferenceChange(ImagePositionKey.self) { position in
            imagePosition = position
        }
    }
}
