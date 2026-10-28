import SwiftUI

// MARK: - Recommended Product Card
struct RecommendedProductCard: View {
    let product: Product
    let onAdd: (CGRect) -> Void

    @State private var added = false
    @State private var buttonFrame: CGRect = .zero
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                            .frame(width: 156, height: 156)
                            .clipped()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 156, height: 156)
                    },
                    failure: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(width: 156, height: 156)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(.systemGray3))
                            )
                    }
                )
                .frame(width: 156, height: 156)

                // Botón añadir (esquina inferior derecha sobre la imagen)
                Button(action: {
                    guard !added else { return }
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) { added = true }
                    onAdd(buttonFrame)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { added = false }
                    }
                }) {
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(scheme == .dark ? Color.llegoPrimary : .white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(CartStyle.ink(scheme))
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        buttonFrame = geo.frame(in: .global)
                                    }
                                    .onChange(of: geo.frame(in: .global)) { _, frame in buttonFrame = frame }
                            }
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(added ? "Agregado al carrito" : "Agregar \(product.name) al carrito")
                .padding(8)
                .scaleEffect(added ? 1.1 : 1.0)
                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: added)
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
        .frame(width: 156)
        .background(CartStyle.surface(scheme))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}
