import SwiftUI

struct ComboCartCard: View {
    let primaryItem: CartItem
    let components: [CartItem]
    let selectedCurrency: String
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

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
                VStack(alignment: .leading, spacing: 6) {
                    Text("COMBO A TU GUSTO")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(CartStyle.ink(scheme))
                    Text(comboHeaderTitle)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(primaryItem.shop)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(currencyLabel) \(String(format: "%.2f", comboUnitPrice)) / combo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quitar combo \(comboHeaderTitle)")
            }

            if comboUnitDiscount > 0.009 {
                Text("Ahorras \(currencyLabel) \(String(format: "%.2f", comboDiscountTotal)) con este combo")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CartStyle.ink(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(isExpanded ? "Ocultar contenido" : "Ver contenido (\(sortedComponents.count))")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .foregroundStyle(CartStyle.ink(scheme))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(CartStyle.inset(scheme), in: RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expandido" : "Contraído")

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(groupedSlots) { slot in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(slot.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(slot.items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.subheadline)
                                    if !item.comboModifierNames.isEmpty {
                                        Text(item.comboModifierNames.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let info = item.currencyInfoText(for: selectedCurrency) {
                                        Text(info).font(.caption).foregroundStyle(.orange)
                                    }
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) { totalLabel; quantityControl }
            } else {
                HStack(spacing: 8) { totalLabel; Spacer(minLength: 4); quantityControl }
            }
        }
        .padding(16)
    }

    private var totalLabel: some View {
        Text("\(currencyLabel) \(String(format: "%.2f", comboTotalPrice))")
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(CartStyle.ink(scheme))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Total del combo: \(currencyLabel) \(String(format: "%.2f", comboTotalPrice))")
    }

    private var quantityControl: some View {
        CartQuantityControl(quantity: quantity, name: comboHeaderTitle, onDecrement: onDecrement, onIncrement: onIncrement)
    }

    private var comboArtwork: some View {
        ZStack {
            CartStyle.inset(scheme)
            if let comboImageURL {
                CachedAsyncImage(
                    url: comboImageURL,
                    content: { $0.resizable().scaledToFill() },
                    placeholder: { ProgressView().tint(CartStyle.ink(scheme)) },
                    failure: { Image(systemName: "shippingbox").foregroundStyle(CartStyle.ink(scheme)) })
            } else {
                Image(systemName: "shippingbox")
                    .font(.title2)
                    .foregroundStyle(CartStyle.ink(scheme))
            }
        }
        .frame(width: typeSize.isAccessibilitySize ? 56 : 76, height: typeSize.isAccessibilitySize ? 56 : 76)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityHidden(true)
    }
}

struct ComboSlotSummary: Identifiable {
    let id: String
    let title: String
    let items: [CartItem]
}
