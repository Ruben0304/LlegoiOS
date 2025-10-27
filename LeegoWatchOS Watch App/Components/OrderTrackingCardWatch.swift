//
//  OrderTrackingCardWatch.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct OrderTrackingCardWatch: View {
    @ObservedObject var orderManager: WatchOrderManager

    // Calcular progreso del delivery (0.0 a 1.0)
    private var deliveryProgress: CGFloat {
        guard orderManager.currentOrder != nil else { return 0 }

        switch orderManager.orderStatus {
        case .idle, .confirmed: return 0.15
        case .preparing: return 0.3
        case .readyForPickup: return 0.5
        case .onTheWay: return 0.75
        case .delivered: return 1.0
        case .cancelled: return 0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.12) {
                    // Estado y tiempo
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: orderManager.orderStatus.icon)
                                .font(.system(size: geometry.size.width * 0.075, weight: .semibold))
                                .foregroundColor(orderManager.orderStatus.color)

                            Text(orderManager.orderStatus.rawValue)
                                .font(.system(size: geometry.size.width * 0.07, weight: .semibold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        Spacer()

                        if orderManager.estimatedMinutesRemaining > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: geometry.size.width * 0.06))
                                    .foregroundColor(.secondary)

                                Text("\(orderManager.estimatedMinutesRemaining) min")
                                    .font(.system(size: geometry.size.width * 0.065, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // Barra de progreso con ícono animado
                    GeometryReader { progressGeometry in
                        let totalWidth = progressGeometry.size.width
                        let progressWidth = max(15, totalWidth * deliveryProgress)

                        ZStack(alignment: .leading) {
                            // Línea de fondo
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: geometry.size.height * 0.06)

                            // Línea de progreso
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary,
                                            Color.llegoAccent
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: progressWidth, height: geometry.size.height * 0.06)
                                .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                        }
                        .overlay(alignment: .leading) {
                            // Ícono de bicicleta animado
                            Image(systemName: "bicycle.circle.fill")
                                .font(.system(size: geometry.size.width * 0.095, weight: .bold))
                                .foregroundColor(.llegoPrimary)
                                .background(
                                    Circle()
                                        .fill(Color(white: 1.0).opacity(0.95))
                                        .frame(width: geometry.size.width * 0.08, height: geometry.size.width * 0.08)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                                .offset(x: max(0, min(progressWidth - (geometry.size.width * 0.0475), totalWidth - (geometry.size.width * 0.095))))
                                .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                        }
                    }
                    .frame(height: geometry.size.height * 0.2)

                    // Destinos
                    HStack(spacing: 0) {
                        // Origen
                        HStack(spacing: 3) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: geometry.size.width * 0.055, weight: .semibold))
                                .foregroundColor(.llegoTertiary)

                            Text("Tienda")
                                .font(.system(size: geometry.size.width * 0.055, weight: .medium))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Destino
                        HStack(spacing: 3) {
                            Text("Tu casa")
                                .font(.system(size: geometry.size.width * 0.055, weight: .medium))
                                .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .secondary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)

                            Image(systemName: "house.fill")
                                .font(.system(size: geometry.size.width * 0.055, weight: .semibold))
                                .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .gray)
                        }
                    }
                }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color.primary.opacity(0.05)
                            .blendMode(.destinationOut)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.thin)
                    )
                    .shadow(color: Color.primary.opacity(0.08), radius: 3, x: 0, y: 2)
            )
        }
        .frame(height: 90)
    }
}

#Preview {
    OrderTrackingCardWatch(
        orderManager: WatchOrderManager.shared
    )
}
