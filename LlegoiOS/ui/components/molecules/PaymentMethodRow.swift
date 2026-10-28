import SwiftUI

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                iconView
                VStack(alignment: .leading, spacing: 6) {
                    Text(method.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(method.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(method.currency)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CartStyle.ink(scheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? CartStyle.ink(scheme) : .secondary.opacity(0.35))
                    .padding(.top, 3)
                    .accessibilityHidden(true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .modifier(CartSurface())
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(isSelected ? CartStyle.ink(scheme) : .clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(!method.isEnabled)
        .opacity(method.isEnabled ? 1 : 0.5)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(CartStyle.inset(scheme))
            switch method.imageType {
            case .systemIcon(let iconName):
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(CartStyle.ink(scheme))
            case .assetImage(let imageName):
                Image(imageName).resizable().scaledToFit().padding(10)
            case .url(let url):
                CachedAsyncImage(
                    url: URL(string: url),
                    content: { $0.resizable().scaledToFit().padding(10) },
                    placeholder: { fallbackIcon },
                    failure: { fallbackIcon })
            }
        }
        .frame(width: 46, height: 46)
        .accessibilityHidden(true)
    }

    private var fallbackIcon: some View {
        Image(systemName: "creditcard").font(.title3).foregroundStyle(CartStyle.ink(scheme))
    }
}
