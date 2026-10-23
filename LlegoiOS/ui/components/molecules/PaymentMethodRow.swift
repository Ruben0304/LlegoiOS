import SwiftUI

/// Fila de método de pago con icono, información y badge de selección
/// Usado en: CartView para seleccionar método de pago
struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    let animationDelay: Double

    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var didAppear = false

    var body: some View {
        Button(action: onTap) {
            rowContent
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(didAppear ? 1 : 0)
        .offset(y: didAppear ? 0 : 12)
        .scaleEffect(didAppear ? 1 : 0.98)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.9).delay(animationDelay)) {
                didAppear = true
            }
        }
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .frame(width: 54, height: 54)

            switch method.imageType {
            case .systemIcon(let iconName):
                Image(systemName: iconName)
                    .scaledFont(size: 22, weight: .semibold, relativeTo: .title2)
                    .foregroundColor(.primary)
                    .opacity(0.8)
            case .assetImage(let imageName):
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            case .url(_):
                Image("imageName")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
        }
    }

    private var badgeView: some View {
        Group {
            if isSelected {
                Capsule()
                    .fill(gradientManager.currentAccentColor.opacity(0.12))
                    .frame(height: 22)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .scaledFont(size: 11, weight: .bold, relativeTo: .caption)
                            Text("Seleccionado")
                                .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                        }
                        .foregroundColor(gradientManager.currentAccentColor)
                        .padding(.horizontal, 8)
                    )
            }
        }
    }

    private var currencyChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "banknote")
                .scaledFont(size: 11, weight: .medium, relativeTo: .caption)
            Text(method.currency)
                .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
        .foregroundColor(.primary.opacity(0.7))
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(method.name)
                    .scaledFont(size: 16, weight: .semibold, design: .rounded, relativeTo: .body)
                    .foregroundColor(.primary)
                badgeView
            }

            Text(method.description)
                .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)

            currencyChip
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            iconView
            infoView
            Spacer()
            Image(systemName: "chevron.forward")
                .scaledFont(size: 12, weight: .semibold, relativeTo: .caption)
                .foregroundColor(.secondary)
                .opacity(0.6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? gradientManager.currentAccentColor : Color.primary.opacity(0.06), lineWidth: isSelected ? 1.6 : 1)
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .contentShape(Rectangle())
    }
}
