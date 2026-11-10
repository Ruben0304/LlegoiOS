import SwiftUI

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethodModel
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                paymentMethodIcon
                    .frame(width: 50, height: 50)
                    .background(iconBackgroundColor.opacity(0.1))
                    .cornerRadius(12)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(paymentMethod.name)
                        .scaledFont(size: 16, weight: .semibold, relativeTo: .body)
                        .foregroundColor(.primary)

                    if let instructions = paymentMethod.instructions, !instructions.isEmpty {
                        Text(instructions)
                            .scaledFont(size: 13, relativeTo: .footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(defaultDescription)
                            .scaledFont(size: 13, relativeTo: .footnote)
                            .foregroundColor(.secondary)
                    }

                    if paymentMethod.commissionPercent > 0 {
                        Text("Comisión: \(String(format: "%.1f", paymentMethod.commissionPercent))%")
                            .scaledFont(size: 11, weight: .medium, relativeTo: .caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // Currency badge
                Text(paymentMethod.currency.uppercased())
                    .scaledFont(size: 12, weight: .bold, relativeTo: .caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(currencyColor)
                    .cornerRadius(8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .scaledFont(size: 24, relativeTo: .title)
                        .foregroundColor(.llegoAccent)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.llegoAccent.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.llegoAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Icon
    
    @ViewBuilder
    private var paymentMethodIcon: some View {
        if let iconUrl = paymentMethod.iconUrl, !iconUrl.isEmpty {
            // Remote icon
            AsyncImage(url: URL(string: iconUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    defaultIcon
                @unknown default:
                    defaultIcon
                }
            }
        } else {
            defaultIcon
        }
    }
    
    @ViewBuilder
    private var defaultIcon: some View {
        let iconName = iconForMethod(paymentMethod.method, code: paymentMethod.code)
        
        if iconName.hasPrefix("asset:") {
            // Asset image
            let assetName = String(iconName.dropFirst(6))
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(8)
        } else {
            // System icon
            Image(systemName: iconName)
                .scaledFont(size: 24, relativeTo: .title)
                .foregroundColor(iconBackgroundColor)
        }
    }
    
    // MARK: - Helpers
    
    private var iconBackgroundColor: Color {
        switch paymentMethod.method.lowercased() {
        case "transfer", "transfermovil":
            return .llegoSecondary
        case "cash":
            return gradientManager.currentAccentColor
        default:
            if paymentMethod.code.contains("tropipay") {
                return Color(red: 0.9, green: 0.4, blue: 0.1)
            }
            return gradientManager.currentAccentColor
        }
    }
    
    private var currencyColor: Color {
        switch paymentMethod.currency.uppercased() {
        case "USD":
            return .green
        case "CUP":
            return .blue
        case "EUR":
            return .purple
        default:
            return .gray
        }
    }
    
    private var defaultDescription: String {
        switch paymentMethod.method.lowercased() {
        case "transfer", "transfermovil":
            return "Transferencia bancaria"
        case "cash":
            return "Pago en efectivo al recibir"
        default:
            return "Método de pago digital"
        }
    }
    
    private func iconForMethod(_ method: String, code: String) -> String {
        switch method.lowercased() {
        case "transfer", "transfermovil":
            return "building.columns.fill"
        case "cash":
            if code.contains("usd") {
                return "dollarsign.circle.fill"
            } else {
                return "banknote.fill"
            }
        default:
            if code.contains("tropipay") {
                return "asset:tropipay"
            }
            return "creditcard.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        PaymentMethodCard(
            paymentMethod: PaymentMethodModel(
                id: "1",
                name: "Efectivo USD",
                code: "cash_usd",
                currency: "USD",
                method: "cash",
                commissionPercent: 0,
                deliveryFeePercent: 0,
                isRefundable: true,
                requiresProof: false,
                requiresBusinessConfirmation: false,
                expirationMinutes: nil,
                isActive: true,
                displayOrder: 1,
                iconUrl: nil,
                instructions: "Paga al recibir"
            ),
            isSelected: true,
            onTap: {}
        )
        
        PaymentMethodCard(
            paymentMethod: PaymentMethodModel(
                id: "2",
                name: "Transfermóvil",
                code: "transfermovil",
                currency: "CUP",
                method: "transfer",
                commissionPercent: 2.5,
                deliveryFeePercent: 0,
                isRefundable: false,
                requiresProof: true,
                requiresBusinessConfirmation: true,
                expirationMinutes: 30,
                isActive: true,
                displayOrder: 2,
                iconUrl: nil,
                instructions: "Transferencia bancaria en CUP"
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}
