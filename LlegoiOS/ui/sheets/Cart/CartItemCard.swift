import SwiftUI

struct CartItemCard: View {
    let item: CartItem
    let selectedCurrency: String
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if item.isShowcase {
                        Text(item.showcaseRequestDescription ?? "Pedido a tu medida")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text([item.shop, item.weight].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(item.formattedPrice(for: selectedCurrency)) / unidad")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quitar \(item.name) del carrito")
            }

            if !item.selectedVariants.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.selectedVariants, id: \.self) { variant in
                        Text(variantSummary(variant))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CartStyle.inset(scheme), in: RoundedRectangle(cornerRadius: 12))
            }

            if let info = item.currencyInfoText(for: selectedCurrency) {
                Label(info, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(scheme == .dark ? .orange : Color(red: 0.5, green: 0.29, blue: 0.04))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    itemTotal
                    quantityControl
                }
            } else {
                HStack(spacing: 8) {
                    itemTotal
                    Spacer(minLength: 4)
                    quantityControl
                }
            }
        }
        .padding(16)
        .accessibilityElement(children: .contain)
    }

    private var itemTotal: some View {
        Text(item.isShowcase ? "Precio por confirmar" : item.formattedItemTotal(for: selectedCurrency))
            .font(.system(item.isShowcase ? .caption : .headline, design: .rounded, weight: .bold))
            .foregroundStyle(CartStyle.ink(scheme))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(item.isShowcase ? "Precio por confirmar" : "Total: \(item.formattedItemTotal(for: selectedCurrency))")
    }

    private var quantityControl: some View {
        CartQuantityControl(
            quantity: item.quantity, name: item.name,
            onDecrement: onDecrement, onIncrement: onIncrement)
    }

    private var artwork: some View {
        ZStack {
            CartStyle.inset(scheme)
            if item.isShowcase && item.imageUrl.isEmpty {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 25))
                    .foregroundStyle(CartStyle.ink(scheme))
            } else {
                CachedAsyncImage(
                    url: URL(string: item.imageUrl),
                    content: { $0.resizable().scaledToFill() },
                    placeholder: { ProgressView().tint(CartStyle.ink(scheme)) },
                    failure: {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    })
            }
        }
        .frame(width: typeSize.isAccessibilitySize ? 56 : 76, height: typeSize.isAccessibilitySize ? 56 : 76)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityHidden(true)
    }

    private func variantSummary(_ variant: SelectedVariantOption) -> String {
        var summary = "\(variant.listName): \(variant.optionName)"
        if variant.priceAdjustment != .zero {
            summary += String(format: " (%@%.2f)", variant.priceAdjustment > .zero ? "+" : "", NSDecimalNumber(decimal: variant.priceAdjustment).doubleValue)
        }
        return summary
    }
}

struct CartDisplayEntry: Identifiable {
    enum Kind {
        case single(CartItem)
        case combo(primaryItem: CartItem, components: [CartItem])
    }

    let id: String
    let kind: Kind
}
