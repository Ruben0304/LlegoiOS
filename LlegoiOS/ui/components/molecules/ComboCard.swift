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
            } else {
                // Multi-image collage (Uber Eats style)
                comboCollageImage
            }
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                    ProgressView().tint(.llegoPrimary)
                }
            },
            failure: {
                comboFallbackImage
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Collage of up to 4 representative product images, similar to Uber Eats bundle UI
    @ViewBuilder
    private var comboCollageImage: some View {
        let images = Array(combo.representativeImageUrls.prefix(4))

        if images.isEmpty {
            comboFallbackImage
        } else if images.count == 1 {
            singleImage(url: images[0], cacheKey: "combo_rep_\(combo.id)_0")
        } else if images.count == 2 {
            HStack(spacing: 2) {
                ForEach(Array(images.enumerated()), id: \.offset) { idx, url in
                    collageCell(url: url, idx: idx)
                }
            }
        } else if images.count == 3 {
            HStack(spacing: 2) {
                collageCell(url: images[0], idx: 0)
                VStack(spacing: 2) {
                    collageCell(url: images[1], idx: 1)
                    collageCell(url: images[2], idx: 2)
                }
            }
        } else {
            // 4-image grid
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    collageCell(url: images[0], idx: 0)
                    collageCell(url: images[1], idx: 1)
                }
                HStack(spacing: 2) {
                    collageCell(url: images[2], idx: 2)
                    collageCell(url: images[3], idx: 3)
                }
            }
        }
    }

    private func collageCell(url: String, idx: Int) -> some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
