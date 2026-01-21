import SwiftUI

struct HDRCreditCardView: View {
    let currency: WalletCurrency
    let amount: Double
    var onReimburseTap: (() -> Void)?

    private var formattedAmount: String {
        String(format: "%.2f", amount)
    }

    private var showsReimburseButton: Bool {
        currency == .cup && onReimburseTap != nil
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cornerRadius = size.height * 0.12
            let basePadding = size.width * 0.06
            let bottomPadding = basePadding + (showsReimburseButton ? size.height * 0.045 : 0)
            let cardShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack {
                cardBackground(size: size)
                    .clipShape(cardShape)

                cardContent(size: size)
                    .padding(.top, basePadding)
                    .padding(.horizontal, basePadding)
                    .padding(.bottom, bottomPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if let onReimburseTap, currency == .cup {
                    reimburseButton(action: onReimburseTap)
                        .padding(basePadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .overlay(
                cardShape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.screen)
            )
            .overlay(
                cardShape
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
                    .blendMode(.overlay)
            )
        }
        .frame(height: 220)
        .shadow(color: currency.cardShadowColor, radius: 24, x: 0, y: 16)
        .shadow(color: currency.cardShadowColor.opacity(0.45), radius: 8, x: 0, y: 6)
    }

    @ViewBuilder
    private func cardBackground(size: CGSize) -> some View {
        let endRadius = max(size.width, size.height) * 2.2

        ZStack {
            HDRGradientView(
                colors: currency.hdrGradientColors,
                locations: currency.hdrGradientLocations,
                center: currency.hdrGradientCenter,
                startRadius: 0,
                endRadius: endRadius,
                type: .radial
            )

            HDRMetallicCardView(
                baseColor: currency.metallicBaseColor,
                metallicIntensity: currency.metallicIntensity,
                roughness: currency.metallicRoughness
            )
            .blendMode(.screen)
            .opacity(0.75)

            HDRGlowView(
                color: currency.sheenGlowColor,
                intensity: 1.6,
                radius: 0.6
            )
            .frame(width: size.width * 1.35, height: size.height * 1.2)
            .offset(x: size.width * 0.3, y: -size.height * 0.35)
            .blendMode(.screen)
            .opacity(0.7)

            HDRHotspotView(
                hotspots: currency.cardHotspots,
                animate: true
            )
            .blendMode(.plusLighter)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.clear,
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
            .opacity(0.7)
        }
    }

    @ViewBuilder
    private func cardContent(size: CGSize) -> some View {
        let logoSize = size.height * 0.075
        let subtitleSize = size.height * 0.038
        let amountSize = size.height * 0.155
        let symbolSize = size.height * 0.08
        let numberSize = size.height * 0.06
        let labelSize = size.height * 0.03
        let valueSize = size.height * 0.042
        let sectionSpacing = size.height * 0.028

        VStack(alignment: .leading, spacing: sectionSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LLEGO")
                        .font(.system(size: logoSize, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundColor(.white.opacity(0.96))
                        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)

                    Text("")
                        .font(.system(size: subtitleSize, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                CardBrandMark(brand: currency.cardBrand, color: .white.opacity(0.9))
            }

            HStack(spacing: size.width * 0.04) {
                CardChipView(tint: currency.chipTint)

                Spacer()

                Image(systemName: "wave.3.right")
                    .font(.system(size: size.height * 0.08, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: size.height * 0.012) {
                Text("BALANCE")
                    .font(.system(size: labelSize, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(currency.symbol)
                        .font(.system(size: symbolSize, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))

                    Text(formattedAmount)
                        .font(.system(size: amountSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer()

                    Text(currency.currencyCode)
                        .font(.system(size: size.height * 0.045, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                                )
                        )
                }
            }

            HStack(spacing: 12) {
                Text(currency.cardNumber)
                    .font(.system(size: numberSize, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .kerning(1.2)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VALID THRU")
                        .font(.system(size: labelSize, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(0.8)

                    Text(currency.cardValidThru)
                        .font(.system(size: valueSize, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Text(currency.cardHolderName)
                    .font(.system(size: valueSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(1.2)
            }
        }
    }

    private func reimburseButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 14))

                Text("Reembolsar")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private enum CardBrand {
    case visa
    case mastercard
    case local
}

private struct CardBrandMark: View {
    let brand: CardBrand
    let color: Color

    var body: some View {
        switch brand {
        case .visa:
            Text("VISA")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(color)
                .italic()
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 2)
        case .mastercard:
            HStack(spacing: -10) {
                Circle()
                    .fill(Color(red: 0.95, green: 0.35, blue: 0.25))
                    .frame(width: 22, height: 22)

                Circle()
                    .fill(Color(red: 0.98, green: 0.65, blue: 0.2))
                    .frame(width: 22, height: 22)
            }
            .frame(width: 40, height: 22)
            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        case .local:
            Text("LLEGO")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

private struct CardChipView: View {
    let tint: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            tint.opacity(0.7),
                            Color.white.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 0.8)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 10, height: 2)
                    }
                }

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 10, height: 2)
                    }
                }
            }
        }
        .frame(width: 50, height: 36)
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

extension WalletCurrency {
    var hdrGradientColors: [HDRGradientView.HDRColor] {
        switch self {
        case .usd:
            return [
                HDRGradientView.HDRColor(color: Color(red: 0.04, green: 0.09, blue: 0.2), intensity: 1.0),
                HDRGradientView.HDRColor(color: Color(red: 0.08, green: 0.22, blue: 0.45), intensity: 1.2),
                HDRGradientView.HDRColor(color: Color(red: 0.16, green: 0.4, blue: 0.7), intensity: 1.4),
                HDRGradientView.HDRColor(color: Color(red: 0.55, green: 0.82, blue: 1.0), intensity: 1.8)
            ]
        case .cup:
            return [
                HDRGradientView.HDRColor(color: Color(red: 0.16, green: 0.05, blue: 0.07), intensity: 1.0),
                HDRGradientView.HDRColor(color: Color(red: 0.32, green: 0.1, blue: 0.12), intensity: 1.2),
                HDRGradientView.HDRColor(color: Color(red: 0.55, green: 0.24, blue: 0.16), intensity: 1.45),
                HDRGradientView.HDRColor(color: Color(red: 0.88, green: 0.6, blue: 0.35), intensity: 1.75)
            ]
        }
    }

    var hdrGradientLocations: [Float] {
        [0.0, 0.35, 0.7, 1.0]
    }

    var hdrGradientCenter: CGPoint {
        switch self {
        case .usd:
            return CGPoint(x: 0.12, y: 0.12)
        case .cup:
            return CGPoint(x: 0.18, y: 0.15)
        }
    }

    var metallicBaseColor: Color {
        switch self {
        case .usd:
            return Color(red: 0.14, green: 0.28, blue: 0.55)
        case .cup:
            return Color(red: 0.5, green: 0.22, blue: 0.16)
        }
    }

    var metallicIntensity: CGFloat {
        switch self {
        case .usd:
            return 0.85
        case .cup:
            return 0.9
        }
    }

    var metallicRoughness: CGFloat {
        switch self {
        case .usd:
            return 0.22
        case .cup:
            return 0.2
        }
    }

    var sheenGlowColor: Color {
        switch self {
        case .usd:
            return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .cup:
            return Color(red: 1.0, green: 0.75, blue: 0.5)
        }
    }

    var cardHotspots: [HDRHotspotView.Hotspot] {
        switch self {
        case .usd:
            return [
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.12, y: 0.18),
                    color: Color(red: 0.8, green: 0.95, blue: 1.0),
                    intensity: 2.4,
                    radius: 0.35
                ),
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.85, y: 0.28),
                    color: Color.white,
                    intensity: 1.8,
                    radius: 0.22
                ),
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.62, y: 0.85),
                    color: Color(red: 0.5, green: 0.75, blue: 1.0),
                    intensity: 1.4,
                    radius: 0.3
                )
            ]
        case .cup:
            return [
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.18, y: 0.22),
                    color: Color(red: 1.0, green: 0.8, blue: 0.6),
                    intensity: 2.2,
                    radius: 0.35
                ),
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.82, y: 0.38),
                    color: Color.white,
                    intensity: 1.6,
                    radius: 0.22
                ),
                HDRHotspotView.Hotspot(
                    position: CGPoint(x: 0.65, y: 0.86),
                    color: Color(red: 1.0, green: 0.6, blue: 0.4),
                    intensity: 1.3,
                    radius: 0.3
                )
            ]
        }
    }

    var cardShadowColor: Color {
        switch self {
        case .usd:
            return Color(red: 0.08, green: 0.15, blue: 0.3).opacity(0.6)
        case .cup:
            return Color(red: 0.3, green: 0.12, blue: 0.12).opacity(0.6)
        }
    }

    var chipTint: Color {
        switch self {
        case .usd:
            return Color(red: 0.95, green: 0.85, blue: 0.55)
        case .cup:
            return Color(red: 0.92, green: 0.78, blue: 0.62)
        }
    }

    var cardNumber: String {
        switch self {
        case .usd:
            return "4761 9024 6815 3016"
        case .cup:
            return "5119 4408 7721 9930"
        }
    }

    var cardHolderName: String {
        "LLEGO USER"
    }

    var cardValidThru: String {
        switch self {
        case .usd:
            return "12/29"
        case .cup:
            return "09/28"
        }
    }

    fileprivate var cardBrand: CardBrand {
        switch self {
        case .usd:
            return .visa
        case .cup:
            return .mastercard
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HDRCreditCardView(
            currency: .usd,
            amount: 1234.56
        )
        .padding(.horizontal, 20)

        HDRCreditCardView(
            currency: .cup,
            amount: 5678.9,
            onReimburseTap: {}
        )
        .padding(.horizontal, 20)
    }
    .padding(.vertical, 40)
    .background(Color.black)
}
