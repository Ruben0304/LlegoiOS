import SwiftUI

struct OrderConfirmationView: View {
    let deliveryLocation: String
    let selectedPaymentMethod: String

    @Environment(\.presentationMode) var presentationMode
    @State private var showContent = false
    @State private var animateSuccess = false
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Fondo con gradiente elegante
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.llegoPrimary.opacity(0.95),
                    Color.llegoAccent.opacity(0.9),
                    Color.llegoPrimary.opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Ícono de éxito con animación elaborada
                ZStack {
                    // Círculos concéntricos animados
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateSuccess ? 1.3 : 0.8)
                        .opacity(animateSuccess ? 0.4 : 0)

                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .scaleEffect(animateSuccess ? 1.2 : 0.9)
                        .opacity(animateSuccess ? 0.6 : 0)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateSuccess ? 1.0 : 0.3)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.llegoAccent)
                        .scaleEffect(animateSuccess ? 1.0 : 0.3)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animateSuccess)

                // Texto principal con animación
                VStack(spacing: 20) {
                    Text("¡Orden Confirmada!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)

                    Text("Tu pedido se procesará correctamente")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)

                    // Información adicional con íconos
                    if showDetails {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Tiempo estimado: 30-45 min")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            HStack(spacing: 16) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Te contactaremos pronto")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }

                            HStack(spacing: 16) {
                                Image(systemName: "truck.box.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Envío a \(deliveryLocation)")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))

                                    Text("Pago: \(selectedPaymentMethod)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()
                            }
                        }
                        .padding(.top, 16)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.8).delay(0.6), value: showContent)
                .animation(.easeInOut(duration: 0.6).delay(1.2), value: showDetails)

                Spacer()

                // Partículas decorativas (simuladas con círculos)
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 10, height: 10)
                            .offset(
                                x: CGFloat(cos(Double(index) * .pi / 4)) * 100,
                                y: CGFloat(sin(Double(index) * .pi / 4)) * 100
                            )
                            .scaleEffect(animateSuccess ? 1.0 : 0.0)
                            .opacity(animateSuccess ? 0.8 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(0.5 + Double(index) * 0.1),
                                value: animateSuccess
                            )
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Secuencia de animaciones
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showContent = true
                    animateSuccess = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showDetails = true
                }
            }

            // Auto-dismissal después de 4 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissToHome()
            }
        }
    }

    private func dismissToHome() {
        withAnimation(.easeInOut(duration: 0.5)) {
            presentationMode.wrappedValue.dismiss()
        }

        // Navegar a la pantalla de inicio (tab 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let contentView = window.rootViewController?.view.subviews.first {
                // Esto es una simulación - en una app real usarías un NavigationController o similar
                NotificationCenter.default.post(name: .navigateToHome, object: nil)
            }
        }
    }
}

// Extensión para la notificación de navegación
extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
}

#Preview {
    OrderConfirmationView(
        deliveryLocation: "Vedado, La Habana",
        selectedPaymentMethod: "Efectivo CUP"
    )
}