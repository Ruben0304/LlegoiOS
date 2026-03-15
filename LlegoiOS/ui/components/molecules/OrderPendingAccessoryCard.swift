import SwiftUI

@available(iOS 26.0, *)
struct OrderPendingAccessoryCard: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @ObservedObject var orderManager: OrderManager
    @ObservedObject private var gradientManager = GradientStateManager.shared
    var onTap: () -> Void

    private var storeImageURL: URL? {
        guard let raw = orderManager.currentOrder?.storeImageUrl, !raw.isEmpty else {
            return nil
        }
        return URL(string: raw)
    }

    private var storeName: String {
        orderManager.currentOrder?.restaurantLocation ?? "Tienda"
    }

    private var statusColor: Color {
        switch orderManager.orderStatus {
        case .pending:
            return .orange
        case .confirmed:
            return .blue
        case .preparing:
            return .purple
        case .inTransit:
            return gradientManager.currentAccentColor
        case .nearDestination:
            return .llegoAccent
        case .delivered:
            return .green
        case .cancelled:
            return .red
        case .idle:
            return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            storeImage
                .frame(width: placement == .inline ? 28 : 36, height: placement == .inline ? 28 : 36)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.llegoTertiary.opacity(0.35), lineWidth: 1.5)
                )

            if placement == .inline {
                Text("Pedido")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pedido")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(storeName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Text(orderManager.orderStatus.displayText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.14))
                )

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var storeImage: some View {
        CachedAsyncImage(
            url: storeImageURL,
            cacheKey: "pending_store_\(orderManager.currentOrder?.id ?? "none")"
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image("generic_logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
        } failure: {
            Image("generic_logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}
