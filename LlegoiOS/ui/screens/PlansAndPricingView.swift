import SwiftUI
import PassKit

struct PlansAndPricingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var isAnimating = false
    @State private var selectedPlan: PlanType = .premium
    @State private var showPaymentSuccess = false
    @State private var showPaymentError = false

    enum PlanType {
        case free, premium
    }

    var body: some View {
        ZStack {
            // Background
            Color.llegoBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    VStack(spacing: 16) {
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoAccent.opacity(0.3),
                                            Color.llegoPrimary.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.llegoAccent)
                                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        }
                        .padding(.top, 32)

                        // Title
                        Text("Elige tu plan ideal")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.llegoPrimary)
                            .multilineTextAlignment(.center)

                        // Subtitle
                        Text("Ahorra tiempo y dinero con nuestros planes diseñados para ti")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.onBackgroundColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 32)

                    // Plans Cards
                    VStack(spacing: 20) {
                        // Premium Plan (Destacado)
                        PlanCard(
                            planType: .premium,
                            isSelected: selectedPlan == .premium,
                            onSelect: { selectedPlan = .premium },
                            onSubscribe: {
                                handleSubscription(planType: .premium)
                            }
                        )

                        // Free Plan
                        PlanCard(
                            planType: .free,
                            isSelected: selectedPlan == .free,
                            onSelect: { selectedPlan = .free },
                            onSubscribe: {
                                handleSubscription(planType: .free)
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    // Comparison Section
                    ComparisonSection()
                        .padding(.top, 32)
                        .padding(.horizontal, 20)

                    // Footer
                    VStack(spacing: 12) {
                        Text("Términos y condiciones")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.llegoTertiary)
                            .underline()

                        Text("Cancela cuando quieras. Sin compromisos.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.onBackgroundColor.opacity(0.6))
                    }
                    .padding(.vertical, 32)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("Planes y Precios")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¡Suscripción Exitosa! 🎉", isPresented: $showPaymentSuccess) {
            Button("Continuar", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Tu suscripción Premium ha sido activada. ¡Disfruta de envíos gratis!")
        }
        .alert("Error en el Pago", isPresented: $showPaymentError) {
            Button("Reintentar", role: .cancel) { }
        } message: {
            Text(paymentManager.lastError ?? "Hubo un problema procesando tu pago. Intenta nuevamente.")
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }

            // Log Apple Pay status for debugging
            print("🍎 Apple Pay Status: \(paymentManager.getApplePayStatus())")
        }
        .onChange(of: paymentManager.paymentStatus) { status in
            switch status {
            case .success:
                showPaymentSuccess = true
            case .failed:
                showPaymentError = true
            default:
                break
            }
        }
    }

    // MARK: - Payment Handling
    private func handleSubscription(planType: PlanType) {
        if planType == .free {
            // Free plan: just confirm
            showPaymentSuccess = true
        } else {
            // Premium plan: process Apple Pay
            let paymentPlanType: PaymentManager.PlanType = planType == .premium ? .premium : .free

            paymentManager.processPayment(for: paymentPlanType) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Payment successful!")
                        // paymentManager will trigger the alert via onChange
                    } else {
                        print("❌ Payment failed: \(error ?? "Unknown error")")
                        paymentManager.lastError = error
                        // paymentManager will trigger the alert via onChange
                    }
                }
            }
        }
    }
}

// MARK: - Plan Card Component
struct PlanCard: View {
    let planType: PlansAndPricingView.PlanType
    let isSelected: Bool
    let onSelect: () -> Void
    let onSubscribe: () -> Void

    @State private var glowAnimation = false

    private var isPremium: Bool {
        planType == .premium
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                // Animated border for premium
                if isPremium {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.llegoAccent,
                                    Color.llegoPrimary,
                                    Color.llegoAccent
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .opacity(glowAnimation ? 1.0 : 0.6)
                }

                // Card content
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(isPremium ? "Premium" : "Gratis")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(isPremium ? .llegoPrimary : .onBackgroundColor)

                                if isPremium {
                                    Text("POPULAR")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.llegoAccent)
                                        )
                                }
                            }

                            if isPremium {
                                Text("AHORRA 40%")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.llegoTertiary)
                            }
                        }

                        Spacer()

                        if isPremium {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.llegoAccent)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.llegoButton)
                        }
                    }

                    // Price
                    if isPremium {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$9.99")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.llegoPrimary)

                            Text("/mes")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.onBackgroundColor.opacity(0.6))
                        }
                    } else {
                        Text("$0")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.onBackgroundColor)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.onBackgroundColor.opacity(0.1))
                        .frame(height: 1)

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        if isPremium {
                            FeatureRow(
                                icon: "shippingbox.fill",
                                text: "Envíos GRATIS en < 5km",
                                highlighted: true
                            )
                            FeatureRow(
                                icon: "percent",
                                text: "Comisión reducida: 8%",
                                highlighted: true
                            )
                            FeatureRow(
                                icon: "bolt.fill",
                                text: "Prioridad en envíos",
                                highlighted: false
                            )
                            FeatureRow(
                                icon: "tag.fill",
                                text: "Descuentos exclusivos",
                                highlighted: false
                            )
                            FeatureRow(
                                icon: "headphones",
                                text: "Soporte prioritario 24/7",
                                highlighted: false
                            )
                        } else {
                            FeatureRow(
                                icon: "shippingbox",
                                text: "Envíos con costo según distancia",
                                highlighted: false
                            )
                            FeatureRow(
                                icon: "percent",
                                text: "Comisión estándar: 15%",
                                highlighted: false
                            )
                            FeatureRow(
                                icon: "bag",
                                text: "Acceso a todas las tiendas",
                                highlighted: false
                            )
                            FeatureRow(
                                icon: "creditcard",
                                text: "Métodos de pago seguros",
                                highlighted: false
                            )
                        }
                    }

                    // CTA Button with Apple Pay
                    Button(action: onSubscribe) {
                        HStack(spacing: 8) {
                            if isPremium {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Pagar con Apple Pay")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            } else {
                                Text("Continuar Gratis")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundColor(isPremium ? .white : .llegoPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if isPremium {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary,
                                            Color.llegoPrimary.opacity(0.85)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoAccent.opacity(0.3),
                                            Color.llegoAccent.opacity(0.2)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: isPremium ? Color.llegoPrimary.opacity(0.4) : Color.clear,
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(
                            color: isPremium ? Color.llegoPrimary.opacity(0.15) : Color.black.opacity(0.06),
                            radius: isPremium ? 20 : 12,
                            x: 0,
                            y: isPremium ? 8 : 4
                        )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            if isPremium {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    glowAnimation = true
                }
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    let highlighted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(highlighted ? .llegoAccent : .llegoButton)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16, weight: highlighted ? .semibold : .regular))
                .foregroundColor(highlighted ? .llegoPrimary : .onBackgroundColor)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.llegoAccent)
        }
    }
}

// MARK: - Comparison Section
struct ComparisonSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Por qué elegir Premium?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)

            VStack(spacing: 12) {
                ComparisonRow(
                    feature: "Costo de envío (< 5km)",
                    freeValue: "$2.50",
                    premiumValue: "GRATIS",
                    isPremiumBetter: true
                )

                ComparisonRow(
                    feature: "Comisión de servicio",
                    freeValue: "15%",
                    premiumValue: "8%",
                    isPremiumBetter: true
                )

                ComparisonRow(
                    feature: "Ahorro mensual estimado",
                    freeValue: "$0",
                    premiumValue: "$25+",
                    isPremiumBetter: true
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Comparison Row
struct ComparisonRow: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    let isPremiumBetter: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(feature)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.onBackgroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Free value
            Text(freeValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.onBackgroundColor.opacity(0.6))
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.onBackgroundColor.opacity(0.05))
                )

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.llegoAccent)

            // Premium value
            Text(premiumValue)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPremiumBetter ? .llegoAccent : .onBackgroundColor)
                .frame(width: 60, alignment: .center)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.llegoAccent.opacity(0.15))
                )
        }
    }
}

#Preview {
    NavigationView {
        PlansAndPricingView()
    }
}
