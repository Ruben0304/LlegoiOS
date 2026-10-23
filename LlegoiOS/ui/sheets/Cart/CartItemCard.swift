import SwiftUI

// MARK: - Cart Item Card

struct CartItemCard: View {
    let item: CartItem
    let selectedCurrency: String
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Imagen del producto circular
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)

                if item.isShowcase && item.imageUrl.isEmpty {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .scaledFont(size: 22, weight: .medium, relativeTo: .title2)
                        .foregroundColor(gradientManager.currentAccentColor)
                } else {
                    CachedAsyncImage(
                        url: URL(string: item.imageUrl),
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        },
                        placeholder: {
                            ProgressView()
                                .tint(Color.gray.opacity(0.6))
                                .scaleEffect(0.85)
                                .frame(width: 56, height: 56)
                        }
                    )
                }
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))

            // Información del producto
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .scaledFont(size: 15, weight: .bold, relativeTo: .subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if item.isShowcase {
                    Text(item.showcaseRequestDescription ?? "")
                        .scaledFont(size: 12, weight: .regular, relativeTo: .caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if item.isComboComponent {
                    HStack(spacing: 6) {
                        Text(item.comboName ?? "Combo")
                            .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                            .foregroundColor(gradientManager.currentAccentColor)
                        if let slotName = item.comboComponentSlotName, !slotName.isEmpty {
                            Text("•")
                                .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                                .foregroundColor(.secondary)
                            Text(slotName)
                                .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.shop)
                            .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                            .foregroundColor(.secondary)

                        Text(item.weight)
                            .scaledFont(size: 11, weight: .medium, relativeTo: .caption2)
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                // Precio y total
                if item.isShowcase {
                    HStack(spacing: 6) {
                        Text("Precio por confirmar")
                            .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                            .foregroundColor(.orange)

                        Text("•")
                            .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                            .foregroundColor(.secondary)

                        Text("Cantidad: \(item.quantity)")
                            .scaledFont(size: 12, weight: .bold, relativeTo: .caption)
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.formattedPrice(for: selectedCurrency))
                            .scaledFont(size: 13, weight: .semibold, relativeTo: .footnote)
                            .foregroundColor(.secondary)

                        Text("× \(item.quantity)")
                            .scaledFont(size: 12, weight: .bold, relativeTo: .caption)
                            .foregroundColor(gradientManager.currentAccentColor)

                        Text("=")
                            .scaledFont(size: 11, weight: .medium, relativeTo: .caption2)
                            .foregroundColor(.secondary)

                        Text(item.formattedItemTotal(for: selectedCurrency))
                            .scaledFont(size: 15, weight: .bold, design: .rounded, relativeTo: .subheadline)
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                if let currencyInfo = item.currencyInfoText(for: selectedCurrency) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                        Text(currencyInfo)
                            .scaledFont(size: 11, weight: .medium, relativeTo: .caption2)
                            .lineLimit(2)
                    }
                    .foregroundColor(.orange.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                    )
                }

                if !item.selectedVariants.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(item.selectedVariants, id: \.self) { variant in
                            HStack(spacing: 4) {
                                Text("\(variant.listName):")
                                    .scaledFont(size: 11, weight: .semibold, relativeTo: .caption2)
                                    .foregroundColor(.secondary)
                                Text(variant.optionName)
                                    .scaledFont(size: 11, weight: .regular, relativeTo: .caption2)
                                    .foregroundColor(.primary)
                                if variant.priceAdjustment != .zero {
                                    Text(
                                        String(
                                            format: "(%@$%.2f)",
                                            variant.priceAdjustment > .zero ? "+" : "",
                                            NSDecimalNumber(decimal: variant.priceAdjustment)
                                                .doubleValue
                                        )
                                    )
                                    .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Controles compactos
            VStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .scaledFont(size: 11, weight: .medium, relativeTo: .caption)
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Eliminar del carrito")

                // Controles de cantidad
                HStack(spacing: 6) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .scaledFont(size: 9, weight: .bold, relativeTo: .caption2)
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Quitar uno")

                    Text("\(item.quantity)")
                        .scaledFont(size: 14, weight: .bold, design: .rounded, relativeTo: .subheadline)
                        .foregroundColor(.primary)
                        .frame(width: 22)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .scaledFont(size: 9, weight: .bold, relativeTo: .caption2)
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Agregar uno")
                }
            }
        }
        .padding(12)
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
