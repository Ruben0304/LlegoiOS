import SwiftUI

// MARK: - Transfer SMS Confirmation View
//
// Flujo:
//   1. Pregunta al usuario si su transferencia envía SMS
//   2a. [Sí] → inicia pedido con sendsSmsNotification=true → muestra pantalla de espera con polling
//   2b. [No] → inicia pedido con sendsSmsNotification=false → cierra para ir al flujo de foto

struct TransferSmsConfirmationView: View {
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject private var gradientManager = GradientStateManager.shared
    let paymentMethodId: String
    let totalAmount: String

    /// Llamado cuando el backend confirma el pago automáticamente (SMS=true y transfer encontrada)
    let onPaymentConfirmed: (PaymentAttemptModel) -> Void
    /// Llamado cuando el usuario elige No SMS → ir al flujo manual de foto
    let onGoToManualFlow: (InitiatePaymentResultModel) -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .askingSms

    enum Phase {
        case askingSms
        case initiating
        case waitingShortcut(paymentAttemptId: String)
        case error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                switch phase {
                case .askingSms:
                    askingSmsView

                case .initiating:
                    initiatingView

                case .waitingShortcut(let attemptId):
                    waitingShortcutView(attemptId: attemptId)

                case .error(let msg):
                    errorView(message: msg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if case .askingSms = phase {
                        Button("Cancelar") { onDismiss() }
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                }
            }
        }
        .onDisappear {
            cartViewModel.stopShortcutPolling()
        }
    }

    // MARK: - Pregunta SMS

    private var askingSmsView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "message.badge.filled.fill")
                    .font(.system(size: 56))
                    .foregroundColor(gradientManager.currentAccentColor)

                Text("¿Tu transferencia enviará SMS?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("El sistema Shortcut puede confirmar tu pago automáticamente si tu banco o Transfermóvil envía un SMS de notificación.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Button {
                    initiatePayment(sendsSms: true)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sí, envía SMS")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Confirmación automática")
                                .font(.system(size: 12))
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(gradientManager.currentAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    initiatePayment(sendsSms: false)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No, sin SMS")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Subiré foto del comprobante")
                                .font(.system(size: 12))
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(gradientManager.currentAccentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(gradientManager.currentAccentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(gradientManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Iniciando pago

    private var initiatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.4)
                .tint(gradientManager.currentAccentColor)
            Text("Iniciando pago...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Esperando confirmación por Shortcut

    private func waitingShortcutView(attemptId: String) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                // Animación de espera
                ZStack {
                    Circle()
                        .stroke(gradientManager.currentAccentColor.opacity(0.1), lineWidth: 6)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(gradientManager.currentAccentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(
                            .linear(duration: 1.2).repeatForever(autoreverses: false),
                            value: cartViewModel.isPollingShortcut
                        )

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }

                VStack(spacing: 8) {
                    Text("Verificando transferencia...")
                        .font(.system(size: 20, weight: .bold, design: .rounded))

                    Text("Buscando tu transferencia en Shortcut.\nEsto puede tardar unos segundos.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)

            // Info del total
            HStack {
                Image(systemName: "banknote")
                    .foregroundColor(.llegoAccent)
                Text("Total: \(totalAmount) CUP")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.llegoAccent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Opción manual si no aparece
            VStack(spacing: 8) {
                Text("¿No aparece tu transferencia?")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Button {
                    cartViewModel.stopShortcutPolling()
                    // Recuperar el attempt actual y pasar al flujo manual
                    if let attempt = cartViewModel.currentPaymentAttempt {
                        let result = InitiatePaymentResultModel(paymentAttempt: attempt, instructions: nil)
                        onGoToManualFlow(result)
                    }
                } label: {
                    Text("Subir comprobante manualmente")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                        .underline()
                }
            }

            Spacer()
        }
        .onAppear {
            startPolling(paymentAttemptId: attemptId)
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Algo salió mal")
                .font(.system(size: 20, weight: .bold))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Volver a intentar") {
                phase = .askingSms
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(gradientManager.currentAccentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Actions

    private func initiatePayment(sendsSms: Bool) {
        phase = .initiating
        cartViewModel.createOrderAndInitiatePayment(
            paymentMethodId: paymentMethodId,
            sendsSmsNotification: sendsSms
        ) { result in
            Task { @MainActor in
                switch result {
                case .success(let (_, paymentResult)):
                    if sendsSms {
                        phase = .waitingShortcut(paymentAttemptId: paymentResult.paymentAttempt.id)
                    } else {
                        onGoToManualFlow(paymentResult)
                    }
                case .failure(let error):
                    phase = .error(error.localizedDescription)
                }
            }
        }
    }

    private func startPolling(paymentAttemptId: String) {
        cartViewModel.startShortcutPolling(
            paymentAttemptId: paymentAttemptId,
            onSuccess: { attempt in
                onPaymentConfirmed(attempt)
            },
            onError: { error in
                // El polling sigue — los errores son normales hasta que aparezca el SMS
                print("⏳ Polling error (normal): \(error.localizedDescription)")
            }
        )
    }
}
