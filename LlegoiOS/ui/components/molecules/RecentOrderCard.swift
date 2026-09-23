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
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 10, x: 0,
                    y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    order.displayStatus.requiresCustomerAction
                        ? order.displayStatus.color.opacity(0.45) : Color.clear,
                    lineWidth: 1.5)
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Store Image
            CachedAsyncImage(
                url: ImageURLResolver.resolve(order.storeImageUrl),
                cacheKey: order.id + "_store"
            ) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    gradientManager.currentAccentColor.opacity(0.1)

                    Image(systemName: "storefront")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            } failure: {
                ZStack {
                    gradientManager.currentAccentColor.opacity(0.1)

                    Image(systemName: "storefront")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
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
        OrderStatusBadge(status: order.displayStatus)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        HStack(spacing: 12) {
            // Items Preview
            HStack(spacing: -8) {
                ForEach(Array(order.items.prefix(3).enumerated()), id: \.element.id) {
                    index, item in
                    CachedAsyncImage(
                        url: ImageURLResolver.resolve(item.imageUrl),
                        cacheKey: "order_item_\(item.id)"
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    } failure: {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
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
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(order.displayStatus.headline(isPickup: order.isPickup))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(order.formattedTotal)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            if let deadlineAt = order.deadlineAt,
                OrderPermissionPolicy.shouldShowDeadline(status: order.status)
            {
                OrderDeadlineNotice(status: order.displayStatus, deadline: deadlineAt, compact: true)
            }

            // La tarjeta entera abre el detalle; esta fila solo deja claro qué hay que hacer.
            // El pago se hace desde el detalle, que tiene las cuentas reales del negocio.
            if let callToAction {
                HStack(spacing: 8) {
                    Image(systemName: order.displayStatus.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(callToAction)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(order.displayStatus.color)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradientManager.currentAccentColor.opacity(0.05))
        )
    }

    // MARK: - Helper Properties

    private var callToAction: String? {
        switch order.displayStatus {
        case .pendingPayment:
            guard OrderPermissionPolicy.isAwaitingCustomerPayment(
                status: order.status, paymentStatus: order.paymentStatus)
            else { return nil }
            return "Pagar \(order.formattedTotal)"
        case .modifiedByStore:
            return "Revisar cambios de la tienda"
        case .rejectedByStore:
            return "Editar y reenviar pedido"
        default:
            return nil
        }
    }
}
