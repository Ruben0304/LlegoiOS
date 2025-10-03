import SwiftUI

struct FamilyPaymentPromoCard: View {
    @State private var isAnimating = false
    var onTap: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoTertiary,
                            Color.llegoTertiary.opacity(0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.llegoTertiary.opacity(0.3), radius: 16, x: 0, y: 8)

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.llegoSecondary.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .offset(x: geometry.size.width - 50, y: -20)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                Circle()
                    .fill(Color.llegoAccent.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .offset(x: -15, y: geometry.size.height - 35)
                    .scaleEffect(isAnimating ? 1.0 : 1.1)
            }

            HStack(spacing: 16) {
                // Left side: Icon and badge
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.llegoSecondary.opacity(0.3))
                            .frame(width: 70, height: 70)

                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.llegoSecondary)
                    }
                    .scaleEffect(isAnimating ? 1.05 : 1.0)

                    // New badge
                    Text("NUEVO")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.llegoTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.llegoSecondary)
                        )
                }
                .padding(.leading, 8)

                // Right side: Text content
                VStack(alignment: .leading, spacing: 8) {
                    // Tag
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("PARA TU FAMILIA")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.llegoSecondary)

                    // Main title
                    Text("Factura a tu familia")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    // Description
                    Text("Envía la factura a un familiar en el extranjero para que pague por ti")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // CTA Button
                    Button(action: onTap) {
                        HStack(spacing: 6) {
                            Text("Saber más")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.llegoTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoSecondary,
                                            Color.white.opacity(0.95)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.llegoSecondary.opacity(0.5), radius: 8, x: 0, y: 4)
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
    FamilyPaymentPromoCard {
        print("Family payment tapped")
    }
    .padding()
    .background(Color.llegoBackground)
}
