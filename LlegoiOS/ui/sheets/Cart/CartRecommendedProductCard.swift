import SwiftUI

// MARK: - Recommended Product Card
struct RecommendedProductCard: View {
    let product: Product
    let onAdd: (CGRect) -> Void

    @State private var added = false
    @State private var buttonFrame: CGRect = .zero
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagen cuadrada
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(
                    url: URL(string: product.imageUrl),
                    cacheKey: "product_\(product.id)",
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 148, height: 148)
                            .clipped()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 148, height: 148)
                    },
                    failure: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 148, height: 148)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(.systemGray3))
                            )
                    }
                )
                .frame(width: 148, height: 148)

                // Botón añadir (esquina inferior derecha sobre la imagen)
                Button(action: {
                    guard !added else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { added = true }
                    onAdd(buttonFrame)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { added = false }
                    }
                }) {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(added ? Color(.systemGreen) : Color(.label))
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        buttonFrame = geo.frame(in: .global)
                                    }
                            }
                        )
                }
                .buttonStyle(.plain)
                .padding(8)
                .scaleEffect(added ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: added)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(product.name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 148)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}
