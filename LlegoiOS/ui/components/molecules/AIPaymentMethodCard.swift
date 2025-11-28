//
//  AIPaymentMethodCard.swift
//  LlegoiOS
//
//  Componente para mostrar métodos de pago en el chat con IA
//

import SwiftUI

struct AIPaymentMethodCard: View {
    let paymentMethod: AIChatPaymentEntity

    // Icono según el tipo de método de pago
    private var paymentIcon: String {
        switch paymentMethod.method.lowercased() {
        case "card", "credit_card", "debit_card", "tarjeta":
            return "creditcard.fill"
        case "cash", "efectivo":
            return "banknote.fill"
        case "transfer", "transferencia":
            return "arrow.left.arrow.right"
        case "paypal":
            return "dollarsign.circle.fill"
        case "apple_pay":
            return "applelogo"
        default:
            return "wallet.pass.fill"
        }
    }

    // Color según el tipo de método de pago
    private var accentColor: Color {
        switch paymentMethod.method.lowercased() {
        case "card", "credit_card", "debit_card", "tarjeta":
            return .blue
        case "cash", "efectivo":
            return .green
        case "transfer", "transferencia":
            return .purple
        case "paypal":
            return Color(red: 0/255, green: 48/255, blue: 135/255) // PayPal blue
        case "apple_pay":
            return .black
        default:
            return .llegoPrimary
        }
    }

    // Símbolo de moneda
    private var currencySymbol: String {
        switch paymentMethod.currency.uppercased() {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "CUP":
            return "$"
        default:
            return paymentMethod.currency
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icono del método de pago
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: paymentIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            // Información del método de pago
            VStack(alignment: .leading, spacing: 6) {
                Text(formatMethodName(paymentMethod.method))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text("Moneda: \(paymentMethod.currency)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Indicador de disponibilidad
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // Formatear nombre del método de pago
    private func formatMethodName(_ method: String) -> String {
        switch method.lowercased() {
        case "card", "credit_card":
            return "Tarjeta de Crédito"
        case "debit_card":
            return "Tarjeta de Débito"
        case "cash", "efectivo":
            return "Efectivo"
        case "transfer", "transferencia":
            return "Transferencia"
        case "paypal":
            return "PayPal"
        case "apple_pay":
            return "Apple Pay"
        default:
            return method.capitalized
        }
    }
}
