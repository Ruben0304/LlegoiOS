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
                        .font(.system(size: 22, weight: .medium))
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if item.isShowcase {
                    Text(item.showcaseRequestDescription ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else if item.isComboComponent {
                    HStack(spacing: 6) {
                        Text(item.comboName ?? "Combo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                        if let slotName = item.comboComponentSlotName, !slotName.isEmpty {
                            Text("•")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(slotName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.shop)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(item.weight)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                // Precio y total
                if item.isShowcase {
                    HStack(spacing: 6) {
                        Text("Precio por confirmar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("•")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Cantidad: \(item.quantity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(item.formattedPrice(for: selectedCurrency))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("× \(item.quantity)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)

                        Text("=")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(item.formattedItemTotal(for: selectedCurrency))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }

                if let currencyInfo = item.currencyInfoText(for: selectedCurrency) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text(currencyInfo)
                            .font(.system(size: 11, weight: .medium))
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
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(variant.optionName)
                                    .font(.system(size: 11, weight: .regular))
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
                                    .font(.system(size: 10, weight: .medium))
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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }

                // Controles de cantidad
                HStack(spacing: 6) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                    }

                    Text("\(item.quantity)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 22)

                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(.thinMaterial)
                            )
                    }
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
