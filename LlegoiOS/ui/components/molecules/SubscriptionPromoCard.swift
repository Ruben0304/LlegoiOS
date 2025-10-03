import SwiftUI

struct SubscriptionPromoCard: View {
    @State private var isAnimating = false
    var onSubscribeTap: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoPrimary,
                            Color.llegoPrimary.opacity(0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 16, x: 0, y: 8)

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.llegoAccent.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .offset(x: geometry.size.width - 60, y: -30)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                Circle()
                    .fill(Color.llegoSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .offset(x: -20, y: geometry.size.height - 40)
                    .scaleEffect(isAnimating ? 1.0 : 1.1)
            }

            HStack(spacing: 16) {
                // Left side: Icon and badge
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.llegoAccent.opacity(0.2))
                            .frame(width: 70, height: 70)

                        Image(systemName: "gift.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.llegoAccent)
                    }
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                    // Free badge
                    Text("GRATIS")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.llegoAccent)
                        )
                }
                .padding(.leading, 8)

                // Right side: Text content
                VStack(alignment: .leading, spacing: 8) {
                    // Tag
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                        Text("OFERTA EXCLUSIVA")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.llegoSecondary)

                    // Main title
                    Text("¡Envíos gratis!")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    // Description
                    Text("En pedidos menores a 5km con tu suscripción")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // CTA Button
                    Button(action: onSubscribeTap) {
                        HStack(spacing: 6) {
                            Text("Suscribirme ahora")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.llegoPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoAccent,
                                            Color.llegoSecondary
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.llegoAccent.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 4)
                }
                .padding(.trailing, 16)
                .padding(.vertical, 16)
            }
        }
        .frame(height: 180)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SubscriptionPromoCard {
        print("Subscribe tapped")
    }
    .padding()
    .background(Color.llegoBackground)
}
