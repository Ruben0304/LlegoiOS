import SwiftUI

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethodModel
    let isSelected: Bool
    let onTap: () -> Void
    
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let instructions = paymentMethod.instructions, !instructions.isEmpty {
                        Text(instructions)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(defaultDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // Commission info
                    if paymentMethod.commissionPercent > 0 {
                        Text("Comisión: \(String(format: "%.1f", paymentMethod.commissionPercent))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Currency badge
                Text(paymentMethod.currency.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(currencyColor)
                    .cornerRadius(8)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
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
                .font(.system(size: 24))
                .foregroundColor(iconBackgroundColor)
        }
    }
    
    // MARK: - Helpers
    
    private var iconBackgroundColor: Color {
        switch paymentMethod.method.lowercased() {
        case "wallet":
            return .llegoAccent
        case "transfer", "transfermovil":
            return .llegoSecondary
        case "stripe", "card":
            return .llegoTertiary
        case "cash":
            return .llegoPrimary
        default:
            if paymentMethod.code.contains("qvapay") {
                return Color(red: 0.2, green: 0.6, blue: 0.9)
            } else if paymentMethod.code.contains("tropipay") {
                return Color(red: 0.9, green: 0.4, blue: 0.1)
            }
            return .llegoPrimary
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
        case "wallet":
            return "Pagar con saldo de wallet"
        case "transfer", "transfermovil":
            return "Transferencia bancaria"
        case "stripe", "card":
            return "Tarjeta de crédito/débito"
        case "cash":
            return "Pago en efectivo al recibir"
        default:
            return "Método de pago digital"
        }
    }
    
    private func iconForMethod(_ method: String, code: String) -> String {
        switch method.lowercased() {
        case "wallet":
            return "wallet.pass.fill"
        case "transfer", "transfermovil":
            return "building.columns.fill"
        case "stripe", "card":
            return "creditcard.fill"
        case "cash":
            if code.contains("usd") {
                return "dollarsign.circle.fill"
            } else {
                return "banknote.fill"
            }
        default:
            if code.contains("qvapay") {
                return "asset:qvapay"
            } else if code.contains("tropipay") {
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
                name: "Wallet USD",
                code: "wallet_usd",
                currency: "USD",
                method: "wallet",
                commissionPercent: 0,
                deliveryFeePercent: 0,
                isRefundable: true,
                requiresProof: false,
                requiresBusinessConfirmation: false,
                expirationMinutes: nil,
                isActive: true,
                displayOrder: 1,
                iconUrl: nil,
                instructions: "Paga con tu saldo disponible"
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
