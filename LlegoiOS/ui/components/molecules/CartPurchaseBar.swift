import SwiftUI

/// Shared purchase controls for products and commercial combos.
struct CartPurchaseBar: View {
    let quantity: Int
    let total: String
    let accent: Color
    let isAdded: Bool
    var isEnabled = true
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onAdd: () -> Void
    var onAddButtonFrameChange: (CGRect) -> Void = { _ in }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        glassContainer
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private var glassContainer: some View {
        if #available(iOS 26.0, macOS 26.0, *), !reduceTransparency {
            GlassEffectContainer(spacing: 10) {
                controls
            }
        } else {
            controls
        }
    }

    private var controls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stackedControls
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        quantityControl
                        addButton()
                    }
                    HStack(spacing: 12) {
                        quantityControl
                        addButton(compact: true)
                    }
                    stackedControls
                }
            }
        }
    }

    private var stackedControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            quantityControl
            addButton()
        }
    }

    private var quantityControl: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
            }
            .disabled(quantity <= 1 || isAdded)
            .accessibilityLabel("Reducir cantidad")

            Text(quantity, format: .number)
                .monospacedDigit()
                .frame(minWidth: 24)
                .fixedSize()
                .accessibilityLabel("Cantidad: \(quantity)")

            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
            }
            .disabled(isAdded)
            .accessibilityLabel("Aumentar cantidad")
        }
        .font(.subheadline.weight(.semibold))
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .modifier(PurchaseGlassSurface(tint: nil, reduceTransparency: reduceTransparency))
    }

    private func addButton(compact: Bool = false) -> some View {
        Button(action: onAdd) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        actionTitle(compact: false)
                        Text(total).monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                } else {
                    HStack(spacing: 8) {
                        actionTitle(compact: compact)
                        Spacer(minLength: 12)
                        Rectangle()
                            .fill(.primary.opacity(0.18))
                            .frame(width: 0.5, height: 16)
                            .accessibilityHidden(true)
                        Text(total)
                            .fontWeight(.medium)
                            .monospacedDigit()
                            .fixedSize()
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 14)
            .foregroundStyle(.primary)
            .modifier(PurchaseGlassSurface(
                tint: (isAdded ? Color.green : accent).opacity(isEnabled ? 0.32 : 0.08),
                reduceTransparency: reduceTransparency))
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .background(CartFlightFrameReader(onChange: onAddButtonFrameChange))
        .disabled(!isEnabled || isAdded)
        .animation(.easeInOut(duration: 0.18), value: isAdded)
        .accessibilityLabel(isAdded ? "Añadido al carrito" : "Añadir al carrito")
        .accessibilityValue("\(quantity) unidades, \(total)")
    }

    @ViewBuilder
    private func actionTitle(compact: Bool) -> some View {
        if compact {
            Label(isAdded ? "Listo" : "Añadir", systemImage: isAdded ? "checkmark" : "cart")
                .fixedSize()
        } else {
            Label(isAdded ? "Añadido" : "Añadir", systemImage: isAdded ? "checkmark" : "cart")
                .contentTransition(.symbolEffect(.replace))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PurchaseGlassSurface: ViewModifier {
    let tint: Color?
    let reduceTransparency: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *), !reduceTransparency {
            content.glassEffect(
                .regular.tint(tint ?? .clear).interactive(),
                in: .rect(cornerRadius: 18, style: .continuous))
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.background)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(tint ?? Color.primary.opacity(0.04))
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                }
        }
    }
}

#Preview("Compra compacta") {
    VStack {
        Spacer()
        CartPurchaseBar(
            quantity: 1, total: "1.640 CUP", accent: .llegoPrimary,
            isAdded: false, onDecrement: {}, onIncrement: {}, onAdd: {})
    }
}
