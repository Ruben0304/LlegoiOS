import SwiftUI

/// The checkout keeps a stable Llego palette as product categories change.
enum CartStyle {
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .llegoAccent : .llegoPrimary
    }

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.065, green: 0.085, blue: 0.08)
            : Color(red: 0.965, green: 0.965, blue: 0.945)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.105, green: 0.13, blue: 0.12) : .white
    }

    static func inset(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.055) : .llegoPrimary.opacity(0.045)
    }
}

struct CartSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(CartStyle.surface(scheme), in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(CartStyle.ink(scheme).opacity(0.07), lineWidth: 1)
            }
    }
}

struct CartSectionHeading: View {
    let number: String
    let title: String
    var detail: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(number)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(CartStyle.ink(scheme))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 3)
    }
}

struct CartHeroHeader: View {
    let count: Int
    let shop: String
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("QUÉ BUENA ELECCIÓN")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(CartStyle.ink(scheme).opacity(0.65))
                Text("Tu carrito.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .tracking(-1.3)
                    .foregroundStyle(CartStyle.ink(scheme))
                Text("\(count) \(count == 1 ? "producto" : "productos") · \(shop)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !typeSize.isAccessibilitySize {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.llegoAccent.opacity(scheme == .dark ? 0.14 : 0.45))
                        .frame(width: 82, height: 90)
                        .rotationEffect(.degrees(-8))
                    Image(systemName: "bag.fill")
                        .font(.system(size: 38, weight: .regular))
                        .foregroundStyle(CartStyle.ink(scheme))
                        .frame(width: 82, height: 90)
                        .rotationEffect(.degrees(-8))
                    Image(systemName: "sparkle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(CartStyle.ink(scheme))
                        .offset(x: 3, y: -5)
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }
}

struct CartQuantityControl: View {
    let quantity: Int
    let name: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .disabled(quantity <= 1)
            .accessibilityLabel("Reducir cantidad de \(name)")
            Text(quantity, format: .number)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: 24)
                .accessibilityLabel("\(quantity) unidades")
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Aumentar cantidad de \(name)")
        }
        .font(.system(.caption, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(CartStyle.ink(scheme))
        .background(CartStyle.inset(scheme), in: Capsule())
        .accessibilityElement(children: .contain)
    }
}

/// A single, visible next action. Selecting a payment method never submits an order.
struct CartCheckoutDock: View {
    let total: String
    let caption: String
    let title: String
    let isBusy: Bool
    let isBlocked: Bool
    let onContinue: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 12) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 5) {
                    totalCaption
                    totalValue
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    totalCaption
                    Spacer(minLength: 4)
                    totalValue
                }
            }
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    if isBusy {
                        ProgressView().tint(.white)
                    }
                    Text(title)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    if !isBusy {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 17)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.llegoPrimary, in: RoundedRectangle(cornerRadius: 19))
                .overlay {
                    RoundedRectangle(cornerRadius: 19)
                        .strokeBorder(Color.llegoAccent.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(isBlocked || isBusy)
            .opacity(isBlocked ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 10)
        .background {
            if reduceTransparency {
                CartStyle.surface(scheme).ignoresSafeArea(edges: .bottom)
            } else {
                Rectangle().fill(.regularMaterial).ignoresSafeArea(edges: .bottom)
            }
        }
        .overlay(alignment: .top) {
            Rectangle().fill(CartStyle.ink(scheme).opacity(0.1)).frame(height: 0.5)
        }
    }

    private var totalCaption: some View {
        Text(caption)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var totalValue: some View {
        Text(total)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(CartStyle.ink(scheme))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct CartReceiptDivider: View {
    var body: some View {
        Line()
            .stroke(.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}
