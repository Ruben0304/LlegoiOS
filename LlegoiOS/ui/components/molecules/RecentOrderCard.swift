import SwiftUI

struct RecentOrderCard: View {
    let order: RecentOrder
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection

            // Divider
            Divider()
                .padding(.horizontal, 16)

            // Content Section
            contentSection

            // Footer Section
            footerSection
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.cardBackground(colorScheme))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Store Image
            AsyncImage(url: URL(string: order.storeImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    ZStack {
                        gradientManager.currentAccentColor.opacity(0.1)

                        Image(systemName: "storefront")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                @unknown default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )

            // Store Info
            VStack(alignment: .leading, spacing: 4) {
                Text(order.storeName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    .lineLimit(1)

                Text(order.orderNumber)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Badge
            statusBadge
        }
        .padding(16)
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: order.status.icon)
                .font(.system(size: 11, weight: .bold))

            Text(order.status.displayName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(order.status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(order.status.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(order.status.color.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Content Section

    private var contentSection: some View {
        HStack(spacing: 12) {
            // Items Preview
            HStack(spacing: -8) {
                ForEach(Array(order.items.prefix(3).enumerated()), id: \.element.id) { index, item in
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .zIndex(Double(3 - index))
                }
            }

            if order.itemCount > 3 {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradientManager.currentAccentColor.opacity(0.12))

                    Text("+\(order.itemCount - 3)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                .frame(width: 48, height: 48)
            }

            Spacer()

            // Item Count
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(order.itemCount) artículo\(order.itemCount > 1 ? "s" : "")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11, weight: .medium))

                    Text(order.formattedDate)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            // Currency Badge
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(gradientManager.currentAccentColor)

                Text(order.currency)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradientManager.currentAccentColor.opacity(0.12))
            )

            Spacer()

            // Total Price
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text(order.formattedTotal)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradientManager.currentAccentColor.opacity(0.05))
        )
    }
}
