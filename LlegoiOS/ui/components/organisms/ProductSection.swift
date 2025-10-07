import SwiftUI

struct ProductSection: View {
    let products: [Product]
    @Binding var productCounts: [String: Int]
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let onSeeMoreClick: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil
    var onProductTap: ((Product) -> Void)? = nil
    var title: String = "Podrías necesitar"
    var actionTitle: String = "Ver más"
    var accentColor: Color = Color(red: 124/255, green: 65/255, blue: 43/255)
    @State private var animationDelay: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))

                Spacer()

                Button(action: onSeeMoreClick) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Products horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                        ProductCard(
                            product: product,
                            count: Binding(
                                get: { productCounts[product.id] ?? 0 },
                                set: { newValue in
                                    productCounts[product.id] = newValue
                                }
                            ),
                            onIncrement: {
                                let currentCount = productCounts[product.id] ?? 0
                                productCounts[product.id] = currentCount + 1
                            },
                            onDecrement: {
                                let currentCount = productCounts[product.id] ?? 0
                                if currentCount > 0 {
                                    productCounts[product.id] = currentCount - 1
                                }
                            },
                            onAddToCartAnimation: onAddToCartAnimation,
                            onProductTap: {
                                onProductTap?(product)
                            }
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                        .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                        .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.05),
                            value: animationDelay
                        )
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    triggerAnimation(for: products.count)
                }
                .onChange(of: products.map(\.id)) { _ in
                    triggerAnimation(for: products.count)
                }
            }
        }
    }

    private func triggerAnimation(for count: Int) {
        animationDelay = 0
        guard count > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animationDelay = Double(count) * 0.1 + 0.1
        }
    }
}
