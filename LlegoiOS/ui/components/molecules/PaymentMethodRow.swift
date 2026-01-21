import SwiftUI

/// Fila de método de pago con icono, información y badge de selección
/// Usado en: CartView para seleccionar método de pago
struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    let animationDelay: Double

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
                    .font(.system(size: 22, weight: .semibold))
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
                    .fill(Color.llegoPrimary.opacity(0.12))
                    .frame(height: 22)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Seleccionado")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.llegoPrimary)
                        .padding(.horizontal, 8)
                    )
            }
        }
    }

    private var currencyChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "banknote")
                .font(.system(size: 11, weight: .medium))
            Text(method.currency)
                .font(.system(size: 12, weight: .semibold))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                badgeView
            }

            Text(method.description)
                .font(.system(size: 13, weight: .medium))
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
                .font(.system(size: 12, weight: .semibold))
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
                .stroke(isSelected ? Color.llegoPrimary : Color.primary.opacity(0.06), lineWidth: isSelected ? 1.6 : 1)
        )
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .contentShape(Rectangle())
    }
}
