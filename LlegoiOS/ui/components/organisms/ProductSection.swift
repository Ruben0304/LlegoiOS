import SwiftUI

struct ProductSection: View {
    let products: [Product]
    @Binding var productCounts: [Int: Int]
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let onSeeMoreClick: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil
    var onProductTap: ((Product) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text("Podrías necesitar")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))

                Spacer()

                Button(action: onSeeMoreClick) {
                    Text("Ver más")
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .foregroundColor(Color(red: 124/255, green: 65/255, blue: 43/255))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Products horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(products, id: \.id) { product in
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
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}