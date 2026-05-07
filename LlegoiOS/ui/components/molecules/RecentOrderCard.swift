import Combine
import SwiftUI

struct RecentOrderCard: View {
    let order: RecentOrder
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingTransferPayment = false
    @State private var now = ServerClock.shared.now
    private let deadlineTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
        .onReceive(deadlineTimer) { _ in now = ServerClock.shared.now }
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
        let status = order.displayStatus
        return HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .bold))

            Text(status.displayName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.25), lineWidth: 1)
        )
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

            if let deadlineAt = order.deadlineAt,
                OrderPermissionPolicy.shouldShowDeadline(status: order.status)
            {
                HStack(spacing: 8) {
                    Image(systemName: deadlineAt <= now ? "clock.badge.xmark" : "hourglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(deadlineAt <= now ? .red : .orange)
                    Text(deadlineBadgeText(deadlineAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            if OrderPermissionPolicy.isTimedOutCancellation(
                status: order.status,
                deadlineAt: order.deadlineAt
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                    Text("Cancelado automáticamente por tiempo vencido")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            // Botón de pagar por transferencia (solo si el pedido está pendiente de pago)
            if shouldShowTransferButton {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingTransferPayment = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .semibold))

                        Text("Pagar por transferencia")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        gradientManager.currentAccentColor,
                                        gradientManager.currentAccentColor.opacity(0.8),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(
                        color: gradientManager.currentAccentColor.opacity(0.3), radius: 8, x: 0,
                        y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradientManager.currentAccentColor.opacity(0.05))
        )
        .sheet(isPresented: $showingTransferPayment) {
            TransferPaymentView(order: order)
        }
    }

    // MARK: - Helper Properties

    /// Determina si se debe mostrar el botón de pagar por transferencia
    private var shouldShowTransferButton: Bool {
        OrderPermissionPolicy.canShowTransferPaymentShortcut(
            status: order.status,
            paymentStatus: order.paymentStatus
        )
    }

    private func deadlineBadgeText(_ deadlineAt: Date) -> String {
        let remaining = Int(deadlineAt.timeIntervalSince(now))
        if remaining <= 0 {
            return "Tiempo vencido"
        }
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "Vence en %02d:%02d", minutes, seconds)
    }
}
