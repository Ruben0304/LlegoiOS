import SwiftUI


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

    @State private var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            imageSection

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(product.weight)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(product.shop)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text(product.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 12, x: 0, y: 6
                )
        )
        .contentShape(Rectangle())
        .modifier(OptionalTapModifier(onTap: onProductTap))
    }

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 245/255, green: 247/255, blue: 250/255))
                .overlay(
                    CachedAsyncImage(
                        url: URL(string: product.imageUrl),
                        content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        },
                        placeholder: {
                            ZStack {
                                Color(red: 240/255, green: 242/255, blue: 246/255)
                                ProgressView()
                                    .tint(.llegoPrimary)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            favoriteButton
        }
        .frame(height: 150)
    }

    private var favoriteButton: some View {
        Button {
            isFavorite.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isFavorite ? Color.red : Color.gray)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
        .padding(10)
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
