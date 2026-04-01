import SwiftUI

struct ComboCartCard: View {
    let primaryItem: CartItem
    let components: [CartItem]
    let selectedCurrency: String
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @ObservedObject private var gradientManager = GradientStateManager.shared

    private var sortedComponents: [CartItem] {
        components.sorted { ($0.comboComponentOrder ?? .max) < ($1.comboComponentOrder ?? .max) }
    }

    private var groupedSlots: [ComboSlotSummary] {
        Dictionary(grouping: sortedComponents) { item in
            item.comboComponentSlotId ?? item.id
        }
        .values
        .compactMap { items -> ComboSlotSummary? in
            let sorted = items.sorted {
                ($0.comboComponentOrder ?? .max) < ($1.comboComponentOrder ?? .max)
            }
            guard let first = sorted.first else { return nil }
            return ComboSlotSummary(
                id: first.comboComponentSlotId ?? first.id,
                title: first.comboComponentSlotName ?? "Selección",
                items: sorted
            )
        }
        .sorted { lhs, rhs in
            let lhsOrder = lhs.items.first?.comboComponentOrder ?? .max
            let rhsOrder = rhs.items.first?.comboComponentOrder ?? .max
            return lhsOrder < rhsOrder
        }
    }

    private var quantity: Int {
        primaryItem.quantity
    }

    private var comboUnitPrice: Double {
        sortedComponents.reduce(0) { $0 + $1.unitPrice(for: selectedCurrency) }
    }

    private var comboUnitSubtotal: Double {
        sortedComponents.reduce(0) { $0 + $1.baseUnitPrice(for: selectedCurrency) }
    }

    private var comboUnitDiscount: Double {
        max(0, comboUnitSubtotal - comboUnitPrice)
    }

    private var comboTotalPrice: Double {
        comboUnitPrice * Double(quantity)
    }

    private var comboSubtotalPrice: Double {
        comboUnitSubtotal * Double(quantity)
    }

    private var comboDiscountTotal: Double {
        comboUnitDiscount * Double(quantity)
    }

    private var comboHeaderTitle: String {
        primaryItem.comboName ?? "Combo"
    }

    private var comboImageURL: URL? {
        guard let raw = sortedComponents.first(where: { !$0.imageUrl.isEmpty })?.imageUrl else {
            return nil
        }
        return URL(string: raw)
    }

    private var currencyLabel: String {
        let uppercased = selectedCurrency.uppercased()
        if uppercased == "USD" || uppercased == "CUP" {
            return uppercased
        }
        return primaryItem.currency.uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                comboArtwork

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("COMBO")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(gradientManager.currentAccentColor.opacity(0.12))
                            )

                        Text(comboHeaderTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }

                    Text("Configurado como una sola selección del carrito")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        if comboUnitDiscount > 0.009 {
                            HStack(spacing: 6) {
                                Text(
                                    "\(currencyLabel) \(String(format: "%.2f", comboSubtotalPrice))"
                                )
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                                .strikethrough()

                                Text(
                                    "Ahorro \(currencyLabel) \(String(format: "%.2f", comboDiscountTotal))"
                                )
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.12))
                                )
                            }
                        }

                        HStack(spacing: 6) {
                            Text("\(currencyLabel) \(String(format: "%.2f", comboUnitPrice))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)

                            Text("× \(quantity)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(gradientManager.currentAccentColor)

                            Text("=")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("\(currencyLabel) \(String(format: "%.2f", comboTotalPrice))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(gradientManager.currentAccentColor)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(groupedSlots) { slot in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(slot.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)

                        ForEach(slot.items, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .center, spacing: 8) {
                                    Circle()
                                        .fill(gradientManager.currentAccentColor.opacity(0.9))
                                        .frame(width: 6, height: 6)

                                    Text(item.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Spacer(minLength: 8)

                                    Text(item.formattedPrice(for: selectedCurrency))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }

                                if !item.comboModifierNames.isEmpty {
                                    Text(item.comboModifierNames.joined(separator: ", "))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 14)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6).opacity(0.8))
                    )
                }
            }

            HStack(spacing: 10) {
                Button(action: onRemove) {
                    Label("Quitar", systemImage: "trash.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.08))
                        )
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    quantityButton(systemName: "minus", action: onDecrement)

                    Text("\(quantity)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 24)

                    quantityButton(systemName: "plus", action: onIncrement)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    gradientManager.currentAccentColor.opacity(0.08),
                    Color.white.opacity(0.98),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var comboArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            gradientManager.currentAccentColor.opacity(0.18),
                            Color(.systemGray5),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)

            if let comboImageURL {
                CachedAsyncImage(
                    url: comboImageURL,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    },
                    placeholder: {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                )
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(gradientManager.currentAccentColor.opacity(0.12), lineWidth: 1)
        )
    }

    private func quantityButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(.thinMaterial)
                )
        }
    }
}

struct ComboSlotSummary: Identifiable {
    let id: String
    let title: String
    let items: [CartItem]
}
