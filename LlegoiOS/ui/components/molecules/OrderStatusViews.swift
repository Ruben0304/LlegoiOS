import SwiftUI

// Piezas de estado de pedido compartidas por lista, detalle y tracking,
// para que un mismo estado se vea y se lea igual en toda la app.

// MARK: - Status Badge

struct OrderStatusBadge: View {
    let status: OrderStatusEnum

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status.icon)
                .font(.system(size: 11, weight: .bold))
            Text(status.displayName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estado: \(status.displayName)")
    }
}

// MARK: - Status Stepper

struct OrderStatusStepper: View {
    let status: OrderStatusEnum
    let isPickup: Bool

    private var steps: [String] { OrderStatusEnum.steps(isPickup: isPickup) }

    var body: some View {
        if let current = status.stepIndex(isPickup: isPickup) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                    stepView(index: index, title: title, current: current)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Paso \(current + 1) de \(steps.count): \(steps[current])")
        }
    }

    private func stepView(index: Int, title: String, current: Int) -> some View {
        let isDone = index < current || (index == current && status == .delivered)
        let isCurrent = index == current && status != .delivered
        let reached = index <= current

        return VStack(spacing: 6) {
            ZStack {
                // Conectores a izquierda y derecha del punto
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(index == 0 ? Color.clear : (reached ? status.color : Color.gray.opacity(0.25)))
                        .frame(height: 3)
                    Rectangle()
                        .fill(
                            index == steps.count - 1
                                ? Color.clear : (index < current ? status.color : Color.gray.opacity(0.25))
                        )
                        .frame(height: 3)
                }

                Circle()
                    .fill(reached ? status.color : Color.gray.opacity(0.25))
                    .frame(width: isCurrent ? 22 : 16, height: isCurrent ? 22 : 16)
                    .overlay {
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                        } else if isCurrent {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                        }
                    }
            }
            .frame(height: 22)

            Text(title)
                .font(.system(size: 10, weight: isCurrent ? .bold : .medium))
                .foregroundColor(reached ? status.color : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Deadline Notice

/// Cuenta atrás del plazo del estado actual. Solo re-renderiza cada segundo mientras
/// está en pantalla (TimelineView), en lugar de un Timer por tarjeta.
struct OrderDeadlineNotice: View {
    let status: OrderStatusEnum
    let deadline: Date
    var compact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let remaining = OrderTimeFormatting.remaining(
                until: deadline, now: ServerClock.shared.now)
            let tint: Color = remaining == nil ? .red : (status.requiresCustomerAction ? .orange : .secondary)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: remaining == nil ? "clock.badge.xmark" : "hourglass")
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                    .foregroundColor(remaining == nil ? .red : .orange)
                Text(
                    remaining.map { status.deadlineMessage(remaining: $0) }
                        ?? "El plazo terminó."
                )
                .font(.system(size: compact ? 12 : 13, weight: .medium))
                .foregroundColor(tint)
                .fixedSize(horizontal: false, vertical: true)
                .monospacedDigit()
                Spacer(minLength: 0)
            }
        }
    }
}
