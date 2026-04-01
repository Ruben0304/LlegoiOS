import SwiftUI
import UIKit

// MARK: - Payment Link Sheet View
struct PaymentLinkSheetView: View {
    let paymentLink: String
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var showCopiedMessage = false

    private var copyButtonGradient: LinearGradient {
        let colors: [Color]
        if showCopiedMessage {
            colors = [gradientManager.currentAccentColor, gradientManager.currentAccentColor]
        } else {
            colors = [
                gradientManager.currentAccentColor,
                gradientManager.currentAccentColor,
            ]
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                HomeGradientBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            gradientManager.currentAccentColor.opacity(0.15),
                                            gradientManager.currentAccentColor.opacity(0.1),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            gradientManager.currentAccentColor,
                                            gradientManager.currentAccentColor,
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)

                        // Title & Description
                        VStack(spacing: 12) {
                            Text("Link de Pago Generado")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(
                                "Comparte este link con alguien en el exterior para que pague tu pedido"
                            )
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        }

                        // Link Container
                        VStack(spacing: 16) {
                            // Link Display
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text(paymentLink)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(.regularMaterial)
                            .cornerRadius(14)

                            // Copy Button
                            Button(action: {
                                UIPasteboard.general.string = paymentLink
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showCopiedMessage = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation {
                                        showCopiedMessage = false
                                    }
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(
                                        systemName: showCopiedMessage
                                            ? "checkmark.circle.fill" : "doc.on.doc.fill"
                                    )
                                    .font(.system(size: 18, weight: .bold))

                                    Text(showCopiedMessage ? "¡Copiado!" : "Copiar Link")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(copyButtonGradient)
                                .cornerRadius(16)
                                .shadow(
                                    color: gradientManager.currentAccentColor.opacity(0.3),
                                    radius: 10,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .scaleEffect(showCopiedMessage ? 1.02 : 1.0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7),
                                value: showCopiedMessage)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Instructions Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Instrucciones")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                InstructionRow(number: "1", text: "Copia el link de pago")
                                InstructionRow(
                                    number: "2", text: "Envíalo por WhatsApp, email o mensaje")
                                InstructionRow(
                                    number: "3",
                                    text: "La persona paga de forma segura (Stripe próximamente)")
                                InstructionRow(
                                    number: "4",
                                    text: "Recibirás una notificación cuando se complete el pago")
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Factura al Exterior")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                }
            }
        }
    }
}
