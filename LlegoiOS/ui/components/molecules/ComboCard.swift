import SwiftUI

// MARK: - Combo UI Model

struct Combo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String?
    let shop: String
    let shopLogoUrl: String
    let basePrice: Double
    let finalPrice: Double
    let savings: Double
    let currency: String
    let discountType: String
    let discountValue: Double
    let slotCount: Int
    /// One representative image per slot, used when there is no combo image
    let representativeImageUrls: [String]

    var formattedFinalPrice: String {
        formatPrice(finalPrice, currency: currency)
    }

    var formattedBasePrice: String {
        formatPrice(basePrice, currency: currency)
    }

    var hasDiscount: Bool {
        savings > 0
    }

    var discountLabel: String {
        switch discountType.uppercased() {
        case "PERCENTAGE":
            return "-\(Int(discountValue))%"
        case "FIXED":
            return "-\(formatPrice(discountValue, currency: currency))"
        default:
            return ""
        }
    }

    private func formatPrice(_ value: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "CUP": symbol = "CUP "
        default: symbol = currency + " "
        }
        return String(format: "\(symbol)%.2f", value)
    }
}

// MARK: - ComboCard

struct ComboCard: View {
    let combo: Combo
    var onTap: (() -> Void)? = nil

    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var isPressed = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(PressableComboButtonStyle(isPressed: $isPressed))
        .buttonBorderShape(.roundedRectangle(radius: 26))
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .compositingGroup()
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            imageSection

            VStack(alignment: .leading, spacing: 4) {
                // Combo name
                Text(combo.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: ceil(UIFont.systemFont(ofSize: 17, weight: .semibold).lineHeight * 2),
                           alignment: .topLeading)

                // Shop info
                HStack(spacing: 4) {
                    if !combo.shopLogoUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: combo.shopLogoUrl),
                            cacheKey: "shop_logo_\(combo.shop)",
                            content: { image in
                                image.resizable().scaledToFill()
                            },
                            placeholder: { Circle().fill(Color.gray.opacity(0.2)) },
                            failure: { Circle().fill(Color.gray.opacity(0.2)) }
                        )
                        .frame(width: 14, height: 14)
                        .clipShape(Circle())
                    }
                    Text(combo.shop)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Slot count badge
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.llegoAccent)
                    Text("\(combo.slotCount) \(combo.slotCount == 1 ? "lote" : "lotes") a elegir")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.llegoAccent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.llegoAccent.opacity(0.12))
                )
                .padding(.top, 2)
            }

            // Price row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(combo.formattedFinalPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if combo.hasDiscount {
                    Text(combo.formattedBasePrice)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .secondary)
                }

                Spacer()

                if combo.hasDiscount && !combo.discountLabel.isEmpty {
                    Text(combo.discountLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(26)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            if let imageUrl = combo.imageUrl, !imageUrl.isEmpty {
                // Single full cover image
                singleImage(url: imageUrl, cacheKey: "combo_\(combo.id)")
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                // Floating circles over white card background — no clip
                comboCollageImage
            }
        }
        .frame(height: 150)
    }

    private func singleImage(url: String, cacheKey: String) -> some View {
        CachedAsyncImage(
            url: URL(string: url),
            cacheKey: cacheKey,
            content: { image in
                image.resizable().scaledToFill()
            },
            placeholder: {
                ZStack {
                    Color(red: 240/255, green: 242/255, blue: 246/255)
                    ProgressView().tint(gradientManager.currentAccentColor)
                }
            },
            failure: {
                comboFallbackImage
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Floating circular images style, similar to Uber Eats bundle UI
    @ViewBuilder
    private var comboCollageImage: some View {
        let images = Array(combo.representativeImageUrls.prefix(3))

        if images.isEmpty {
            comboFallbackImage
        } else if images.count == 1 {
            singleImage(url: images[0], cacheKey: "combo_rep_\(combo.id)_0")
        } else {
            floatingCirclesLayout(images: images)
        }
    }

    /// Three (or two) circular product images floating over the card's white background
    private func floatingCirclesLayout(images: [String]) -> some View {
        GeometryReader { geo in
            ZStack {
                let circleSize: CGFloat = geo.size.height * 0.52
                let overlap: CGFloat = circleSize * 0.32
                let count = CGFloat(images.count)
                let totalWidth = circleSize * count - overlap * (count - 1)
                let startX = (geo.size.width - totalWidth) / 2 + circleSize / 2

                ForEach(Array(images.enumerated()), id: \.offset) { idx, url in
                    let xOffset = startX + CGFloat(idx) * (circleSize - overlap)
                    // Slight vertical stagger for depth
                    let yOffset = geo.size.height / 2 + (idx == 1 ? 4 : 0)

                    circleCell(url: url, idx: idx, size: circleSize)
                        .position(x: xOffset, y: yOffset)
                        // Later circles drawn on top via zIndex
                        .zIndex(Double(images.count - idx))
                }
            }
        }
    }

    private func circleCell(url: String, idx: Int, size: CGFloat) -> some View {
        CachedAsyncImage(
            url: URL(string: url),
            cacheKey: "combo_rep_\(combo.id)_\(idx)",
            content: { image in
                image.resizable().scaledToFill()
            },
            placeholder: {
                Color(red: 240/255, green: 242/255, blue: 246/255)
            },
            failure: {
                Color(red: 240/255, green: 242/255, blue: 246/255)
            }
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
    }

    private var comboFallbackImage: some View {
        ZStack {
            Color(red: 240/255, green: 242/255, blue: 246/255)
            VStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray.opacity(0.4))
            }
        }
    }
}

// ButtonStyle para detectar pressed state
private struct PressableComboButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}
