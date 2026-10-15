import SwiftUI

struct SearchCartSuggestionsView: View {
    let context: SearchCartContext
    let suggestions: [SearchCombinationCandidate]
    let onProductTap: (String) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                header

                VStack(spacing: 10) {
                    ForEach(suggestions.prefix(4), id: \.id) { product in
                        suggestionRow(product)
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.llegoPrimary.opacity(0.10), lineWidth: 1)
            }
            .accessibilityElement(children: .contain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("En el mismo negocio", systemImage: "bag")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.llegoPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.llegoAccent.opacity(0.30), in: Capsule())

            Text(cartSummary)
                .font(.headline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("También tienen estas opciones para acompañar tu pedido")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var cartSummary: String {
        if context.cartProductNames.count == 1, let productName = context.cartProductNames.first {
            return "Ya tienes \(productName) en \(context.branchName)"
        }
        return "Ya tienes productos de \(context.branchName)"
    }

    private func suggestionRow(_ product: SearchCombinationCandidate) -> some View {
        Button {
            onProductTap(product.id)
        } label: {
            HStack(spacing: 12) {
                productImage(product)

                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(formattedPrice(product.price, currency: product.currency))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.llegoPrimary)
                        .accessibilityLabel("Precio: \(formattedPrice(product.price, currency: product.currency))")
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.llegoPrimary.opacity(0.7))
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ver opciones de \(product.name), \(formattedPrice(product.price, currency: product.currency))")
        .accessibilityHint("Abre el detalle del producto")
    }

    @ViewBuilder
    private func productImage(_ product: SearchCombinationCandidate) -> some View {
        CachedAsyncImage(
            url: product.imageUrl.flatMap(URL.init(string:)),
            cacheKey: "search_cart_suggestion_\(product.id)",
            displaySize: CGSize(width: 72, height: 72),
            content: { image in
                image.resizable().scaledToFill()
            },
            placeholder: {
                imagePlaceholder
            },
            failure: {
                imagePlaceholder
            }
        )
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.llegoPrimary.opacity(0.08))
            .overlay {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(Color.llegoPrimary.opacity(0.55))
            }
    }

    private func formattedPrice(_ price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f %@", price, currency)
    }
}
