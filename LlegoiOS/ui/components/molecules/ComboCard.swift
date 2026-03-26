import SwiftUI

// MARK: - Combo UI Model

struct Combo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String?
    let shop: String
    let shopLogoUrl: String
    let finalPrice: Double
    let savings: Double
    let startingFinalPrice: Double?
    let startingSavings: Double?
    let currency: String
    let discountType: String
    let discountValue: Double
    let slotCount: Int
    let giftOptionsCount: Int
    let hasFreeSlots: Bool
    /// One representative image per slot, used when there is no combo image
    let representativeImageUrls: [String]

    // Computed base prices from finalPrice + savings
    var basePrice: Double { finalPrice + savings }
    var startingBasePrice: Double? {
        guard let f = startingFinalPrice, let s = startingSavings else { return nil }
        return f + s
    }

    var formattedFinalPrice: String { formatPrice(finalPrice, currency: currency) }
    var formattedFromPrice: String { "Desde \(formatPrice(startingFinalPrice ?? finalPrice, currency: currency))" }
    var formattedStartingBasePrice: String? {
        guard let startingBasePrice else { return nil }
        return formatPrice(startingBasePrice, currency: currency)
    }
    var formattedBasePrice: String { formatPrice(basePrice, currency: currency) }

    var hasDiscount: Bool { savings > 0.009 }
    var hasStartingDiscount: Bool {
        guard let f = startingFinalPrice, let s = startingSavings else { return hasDiscount }
        return s > 0.009 || (f + s) - f > 0.009
    }

    var discountLabel: String {
        switch discountType.uppercased() {
        case "PERCENTAGE": return "-\(Int(discountValue))%"
        case "FIXED": return "-\(formatPrice(discountValue, currency: currency))"
        default: return ""
        }
    }

    var comboKind: ComboKind {
        if giftOptionsCount > 0 { return .withGifts }
        if hasFreeSlots { return .withFreeSlots }
        switch discountType.uppercased() {
        case "PERCENTAGE", "FIXED": return .discounted
        default: return .bundle
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
                Text(combo.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: ceil(UIFont.systemFont(ofSize: 17, weight: .semibold).lineHeight * 2),
                           alignment: .topLeading)

                HStack(spacing: 4) {
                    if !combo.shopLogoUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: combo.shopLogoUrl),
                            cacheKey: "shop_logo_\(combo.shop)",
                            content: { image in image.resizable().scaledToFill() },
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
            }

            // Combo kind badge
            comboKindBadge

            // Price row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(combo.formattedFromPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                if combo.hasStartingDiscount, let formattedStartingBasePrice = combo.formattedStartingBasePrice {
                    Text(formattedStartingBasePrice)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .strikethrough(true, color: .secondary)
                }

                Spacer()

                if combo.comboKind == .discounted && combo.hasDiscount && !combo.discountLabel.isEmpty {
                    Text(combo.discountLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(26)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }

    @ViewBuilder
    private var comboKindBadge: some View {
        switch combo.comboKind {
        case .discounted:
            EmptyView()  // discount shown in price row

        case .withGifts:
            HStack(spacing: 4) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(combo.giftOptionsCount == 1
                     ? "1 regalo incluido"
                     : "\(combo.giftOptionsCount) regalos incluidos")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.purple)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.purple.opacity(0.1)))

        case .withFreeSlots:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("Complementos gratis")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.orange.opacity(0.1)))

        case .bundle:
            HStack(spacing: 4) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("\(combo.slotCount) \(combo.slotCount == 1 ? "lote" : "lotes")")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(gradientManager.currentAccentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(gradientManager.currentAccentColor.opacity(0.1)))
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            if let imageUrl = combo.imageUrl, !imageUrl.isEmpty {
                singleImage(url: imageUrl, cacheKey: "combo_\(combo.id)")
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                comboCollageImage
            }
        }
        .frame(height: 150)
        .overlay(alignment: .topTrailing) {
            // Kind overlay on image for gift and free slot types
            if combo.comboKind == .withGifts {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.purple))
                    .padding(10)
            } else if combo.comboKind == .withFreeSlots {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.orange))
                    .padding(10)
            }
        }
    }

    private func singleImage(url: String, cacheKey: String) -> some View {
        CachedAsyncImage(
            url: URL(string: url),
            cacheKey: cacheKey,
            content: { image in image.resizable().scaledToFill() },
            placeholder: {
                ZStack {
                    Color(red: 240/255, green: 242/255, blue: 246/255)
                    ProgressView().tint(gradientManager.currentAccentColor)
                }
            },
            failure: { comboFallbackImage }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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
                    let yOffset = geo.size.height / 2 + (idx == 1 ? 4 : 0)

                    circleCell(url: url, idx: idx, size: circleSize)
                        .position(x: xOffset, y: yOffset)
                        .zIndex(Double(images.count - idx))
                }
            }
        }
    }

    private func circleCell(url: String, idx: Int, size: CGFloat) -> some View {
        CachedAsyncImage(
            url: URL(string: url),
            cacheKey: "combo_rep_\(combo.id)_\(idx)",
            content: { image in image.resizable().scaledToFill() },
            placeholder: { Color(red: 240/255, green: 242/255, blue: 246/255) },
            failure: { Color(red: 240/255, green: 242/255, blue: 246/255) }
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 4)
    }

    private var comboFallbackImage: some View {
        ZStack {
            Color(red: 240/255, green: 242/255, blue: 246/255)
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.4))
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
