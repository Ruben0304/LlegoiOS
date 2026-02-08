import SwiftUI

@available(iOS 26.0, *)
struct OrderTrackingCard: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    @ObservedObject var orderManager: OrderManager
    var onTap: () -> Void

    // Distancia restante formateada
    private var formattedDistance: String {
        let meters = orderManager.remainingDistanceMeters
        if meters <= 0 { return "0 m" }
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // Calcular progreso del camión (0.0 a 1.0)
    private var deliveryProgress: CGFloat {
        guard orderManager.currentOrder != nil else { return 0 }

        switch orderManager.orderStatus {
        case .idle, .pending: return 0
        case .confirmed: return 0.15
        case .preparing: return 0.3
        case .inTransit: return 0.6
        case .nearDestination: return 0.9
        case .delivered: return 1.0
        case .cancelled: return 0
        }
    }

    var body: some View {
        let timeRemaining = orderManager.estimatedMinutesRemaining

        HStack(spacing: 0) {
            if placement != .inline {
                // Icono de origen (tienda)
                VStack(spacing: 4) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.llegoTertiary)

                    Text("Origen")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)

                // Línea de progreso con motocicleta
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Línea de fondo (gris completa)
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: geometry.size.width, height: 3)

                        // Línea de progreso (verde que se pinta progresivamente)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoPrimary,
                                        Color.llegoAccent,
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * deliveryProgress, height: 3)
                            .animation(.easeInOut(duration: 0.8), value: deliveryProgress)

                        // Motocicleta animada
                        Image(systemName: "bicycle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.llegoPrimary)
                            .offset(
                                x: max(
                                    0,
                                    min(
                                        (geometry.size.width * deliveryProgress) - 8,
                                        geometry.size.width - 16))
                            )
                            .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                    }
                    .frame(height: 20)
                }
                .frame(height: 20)
                .padding(.horizontal, 8)

                // Icono de destino (casa)
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .gray)

                    Text("Destino")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .secondary)
                }
                .frame(width: 50)

                // Distancia restante
                if orderManager.remainingDistanceMeters > 0 {
                    VStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.llegoAccent)
                        Text(formattedDistance)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.llegoPrimary)
                    }
                    .frame(width: 55)
                }

                Spacer()

                // Información de estado
                //                VStack(alignment: .trailing, spacing: 3) {
                //                    Text("En camino")
                //                        .font(.system(size: 11, weight: .bold))
                //                        .foregroundColor(.primary)
                //                        .lineLimit(1)
                //
                //                    HStack(spacing: 4) {
                //                        if timeRemaining > 0 {
                //                            Image(systemName: "clock.fill")
                //                                .font(.system(size: 10))
                //                                .foregroundColor(.llegoAccent)
                //
                //                            Text("\(timeRemaining) min")
                //                                .font(.system(size: 11, weight: .semibold))
                //                                .foregroundColor(.llegoPrimary)
                //                        } else {
                //                            Image(systemName: "checkmark.circle.fill")
                //                                .font(.system(size: 10))
                //                                .foregroundColor(.green)
                //
                //                            Text("Entregado")
                //                                .font(.system(size: 11, weight: .semibold))
                //                                .foregroundColor(.green)
                //                        }
                //                    }
                //                }
                //                .frame(width: 85)

                // Botón de acción
                Button(action: onTap) {
                    Text("Ver")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary,
                                            Color.llegoPrimary.opacity(0.8),
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.leading, 8)
            } else {
                // Diseño compacto sólo con origen, progreso y destino
                VStack(spacing: 4) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.llegoTertiary)

                    Text("Origen")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: geometry.size.width, height: 3)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoPrimary,
                                        Color.llegoAccent,
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * deliveryProgress, height: 3)
                            .animation(.easeInOut(duration: 0.8), value: deliveryProgress)

                        Image(systemName: "bicycle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.llegoPrimary)
                            .offset(
                                x: max(
                                    0,
                                    min(
                                        (geometry.size.width * deliveryProgress) - 8,
                                        geometry.size.width - 16))
                            )
                            .animation(.easeInOut(duration: 0.8), value: deliveryProgress)
                    }
                    .frame(height: 20)
                }
                .frame(height: 20)
                .padding(.horizontal, 8)

                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .gray)

                    Text("Destino")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(deliveryProgress >= 1.0 ? .llegoAccent : .secondary)
                }
                .frame(width: 50)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
