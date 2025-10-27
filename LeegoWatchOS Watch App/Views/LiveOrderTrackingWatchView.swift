//
//  LiveOrderTrackingWatchView.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct LiveOrderTrackingWatchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var orderManager = WatchOrderManager.shared
    @State private var currentTab = 0

    var body: some View {
        TabView(selection: $currentTab) {
            // Tab 1: Progreso visual
            OrderProgressView(orderManager: orderManager)
                .tag(0)

            // Tab 2: Detalles del pedido
            OrderDetailsView(orderManager: orderManager)
                .tag(1)

            // Tab 3: Info del mensajero
            if let deliveryPerson = orderManager.currentOrder?.deliveryPerson {
                DeliveryPersonView(deliveryPerson: deliveryPerson)
                    .tag(2)
            }
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle("Rastreando")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Order Progress View
struct OrderProgressView: View {
    @ObservedObject var orderManager: WatchOrderManager

    private var deliveryProgress: CGFloat {
        guard orderManager.currentOrder != nil else { return 0 }

        switch orderManager.orderStatus {
        case .idle, .confirmed: return 0.2
        case .preparing: return 0.4
        case .readyForPickup: return 0.6
        case .onTheWay: return 0.85
        case .delivered: return 1.0
        case .cancelled: return 0
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height * 0.025) {
                    // Estado actual destacado
                    VStack(spacing: geometry.size.height * 0.01) {
                        ZStack {
                            Circle()
                                .fill(orderManager.orderStatus.color.opacity(0.2))
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)

                            Image(systemName: orderManager.orderStatus.icon)
                                .font(.system(size: geometry.size.width * 0.18, weight: .medium))
                                .foregroundColor(orderManager.orderStatus.color)
                        }

                        Text(orderManager.orderStatus.rawValue)
                            .font(.system(size: geometry.size.width * 0.085, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)

                        if orderManager.estimatedMinutesRemaining > 0 {
                            Text("\(orderManager.estimatedMinutesRemaining) min aprox.")
                                .font(.system(size: geometry.size.width * 0.07, weight: .medium))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.top, geometry.size.height * 0.02)

                    // Barra de progreso circular
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: geometry.size.width * 0.04)
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)

                        Circle()
                            .trim(from: 0, to: deliveryProgress)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoPrimary,
                                        Color.llegoAccent
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: geometry.size.width * 0.04, lineCap: .round)
                            )
                            .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: deliveryProgress)

                        VStack(spacing: 2) {
                            Text("\(Int(deliveryProgress * 100))%")
                                .font(.system(size: geometry.size.width * 0.12, weight: .bold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.7)

                            Text("Completado")
                                .font(.system(size: geometry.size.width * 0.06, weight: .medium))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.7)
                        }
                    }

                    // Timeline de estados
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
                        TimelineItem(
                            icon: "checkmark.circle.fill",
                            title: "Confirmado",
                            isCompleted: true,
                            color: .llegoAccent,
                            geometry: geometry
                        )

                        TimelineItem(
                            icon: "timer.circle.fill",
                            title: "Preparando",
                            isCompleted: orderManager.orderStatus.rawValue != "Confirmado",
                            color: .orange,
                            geometry: geometry
                        )

                        TimelineItem(
                            icon: "bicycle.circle.fill",
                            title: "En camino",
                            isCompleted: orderManager.orderStatus == .onTheWay || orderManager.orderStatus == .delivered,
                            color: .llegoPrimary,
                            geometry: geometry
                        )

                        TimelineItem(
                            icon: "house.circle.fill",
                            title: "Entregado",
                            isCompleted: orderManager.orderStatus == .delivered,
                            color: .green,
                            geometry: geometry
                        )
                    }
                    .padding(.horizontal, 5)
                }
                .padding(.horizontal, 10)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct TimelineItem: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    let color: Color
    let geometry: GeometryProxy

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: geometry.size.width * 0.09, weight: .semibold))
                .foregroundColor(isCompleted ? color : .gray)

            Text(title)
                .font(.system(size: geometry.size.width * 0.075, weight: .medium))
                .foregroundColor(isCompleted ? .primary : .secondary)
                .minimumScaleFactor(0.7)

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: geometry.size.width * 0.065, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Order Details View
struct OrderDetailsView: View {
    @ObservedObject var orderManager: WatchOrderManager

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height * 0.02) {
                    // Header
                    VStack(spacing: geometry.size.height * 0.008) {
                        Text("Detalles del pedido")
                            .font(.system(size: geometry.size.width * 0.085, weight: .bold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)

                        if let order = orderManager.currentOrder {
                            Text(order.orderNumber)
                                .font(.system(size: geometry.size.width * 0.07, weight: .medium))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.top, geometry.size.height * 0.02)

                    // Productos
                    if let order = orderManager.currentOrder {
                        VStack(spacing: geometry.size.height * 0.012) {
                            ForEach(order.items) { item in
                                HStack(spacing: 8) {
                                    AsyncImage(url: URL(string: item.imageUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        default:
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: geometry.size.width * 0.15, height: geometry.size.width * 0.15)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: geometry.size.width * 0.065, weight: .medium))
                                            .foregroundColor(.primary)
                                            .minimumScaleFactor(0.7)
                                            .lineLimit(1)

                                        Text("\(item.quantity)x")
                                            .font(.system(size: geometry.size.width * 0.055, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .minimumScaleFactor(0.7)
                                    }

                                    Spacer()
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, geometry.size.height * 0.01)

                        // Total
                        HStack {
                            Text("Total")
                                .font(.system(size: geometry.size.width * 0.075, weight: .bold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.7)

                            Spacer()

                            Text(order.total)
                                .font(.system(size: geometry.size.width * 0.075, weight: .bold))
                                .foregroundColor(.llegoPrimary)
                                .minimumScaleFactor(0.7)
                        }

                        Divider()
                            .padding(.vertical, geometry.size.height * 0.01)

                        // Dirección
                        VStack(alignment: .leading, spacing: geometry.size.height * 0.008) {
                            HStack(spacing: 5) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: geometry.size.width * 0.065))
                                    .foregroundColor(.llegoAccent)

                                Text("Dirección")
                                    .font(.system(size: geometry.size.width * 0.065, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.7)
                            }

                            Text(order.deliveryAddress)
                                .font(.system(size: geometry.size.width * 0.06, weight: .regular))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

// MARK: - Delivery Person View
struct DeliveryPersonView: View {
    let deliveryPerson: WatchDeliveryPerson

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: geometry.size.height * 0.02) {
                    // Header
                    Text("Mensajero")
                        .font(.system(size: geometry.size.width * 0.085, weight: .bold))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .padding(.top, geometry.size.height * 0.02)

                    // Foto del mensajero
                    AsyncImage(url: URL(string: deliveryPerson.profileImageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.llegoPrimary, lineWidth: 2.5)
                                )
                        default:
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: geometry.size.width * 0.15))
                                        .foregroundColor(.gray)
                                )
                        }
                    }

                    // Nombre y rating
                    VStack(spacing: geometry.size.height * 0.008) {
                        Text(deliveryPerson.name)
                            .font(.system(size: geometry.size.width * 0.08, weight: .semibold))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: geometry.size.width * 0.06))
                                .foregroundColor(.yellow)

                            Text(String(format: "%.1f", deliveryPerson.rating))
                                .font(.system(size: geometry.size.width * 0.065, weight: .medium))
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.7)
                        }
                    }

                    Divider()
                        .padding(.vertical, geometry.size.height * 0.01)

                    // Vehículo
                    VStack(alignment: .leading, spacing: geometry.size.height * 0.01) {
                        HStack(spacing: 5) {
                            Image(systemName: "bicycle")
                                .font(.system(size: geometry.size.width * 0.065))
                                .foregroundColor(.llegoPrimary)

                            Text("Vehículo")
                                .font(.system(size: geometry.size.width * 0.065, weight: .semibold))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.7)
                        }

                        Text("\(deliveryPerson.vehicleType) • \(deliveryPerson.vehiclePlate)")
                            .font(.system(size: geometry.size.width * 0.06, weight: .regular))
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Botón de llamar
                    Button(action: {
                        // Acción de llamar
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: geometry.size.width * 0.075))

                            Text("Llamar")
                                .font(.system(size: geometry.size.width * 0.075, weight: .semibold))
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, geometry.size.height * 0.05)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.llegoPrimary,
                                            Color.llegoButton
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LiveOrderTrackingWatchView()
    }
}
