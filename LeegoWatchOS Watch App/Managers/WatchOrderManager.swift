//
//  WatchOrderManager.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI
import CoreLocation
import Combine

@MainActor
class WatchOrderManager: ObservableObject {
    static let shared = WatchOrderManager()

    @Published var currentOrder: WatchOrder?
    @Published var lastOrder: WatchOrder?
    @Published var orderStatus: WatchOrderStatus = .idle
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var estimatedMinutesRemaining: Int = 0

    private var timer: Timer?
    private var statusTransitionTimer: Timer?

    private init() {}

    // Simula un pedido activo
    func startMockOrder() {
        let mockItems = [
            WatchOrderItem(
                id: "1",
                name: "Hamburguesa Clásica",
                quantity: 2,
                price: "$150.00",
                imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200"
            ),
            WatchOrderItem(
                id: "2",
                name: "Papas Fritas",
                quantity: 1,
                price: "$50.00",
                imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=200"
            ),
            WatchOrderItem(
                id: "3",
                name: "Refresco",
                quantity: 2,
                price: "$40.00",
                imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200"
            )
        ]

        let mockDeliveryPerson = WatchDeliveryPerson(
            id: "driver1",
            name: "Carlos Rodríguez",
            rating: 4.8,
            phoneNumber: "+53 5234-5678",
            vehicleType: "Motocicleta",
            vehiclePlate: "ABC-123",
            profileImageUrl: "https://i.pravatar.cc/150?img=33"
        )

        let storeCoord = CLLocationCoordinate2D(latitude: 23.1352, longitude: -82.3667)
        let deliveryCoord = CLLocationCoordinate2D(latitude: 23.1143, longitude: -82.3673)

        let order = WatchOrder(
            id: UUID().uuidString,
            orderNumber: "#\(Int.random(in: 1000...9999))",
            storeName: "El Rincón del Sabor",
            storeLogoUrl: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200",
            deliveryAddress: "Calle 23 #456, Vedado, La Habana",
            estimatedDeliveryTime: Date().addingTimeInterval(25 * 60),
            items: mockItems,
            total: "$240.00",
            status: .confirmed,
            deliveryPerson: mockDeliveryPerson,
            timeline: [],
            storeLocation: storeCoord,
            deliveryLocation: deliveryCoord,
            currentDeliveryLocation: storeCoord
        )

        self.currentOrder = order
        self.lastOrder = order
        self.orderStatus = .confirmed
        self.driverLocation = storeCoord
        self.estimatedMinutesRemaining = 25

        startTracking()
    }

    // Simula el tracking en tiempo real
    private func startTracking() {
        timer?.invalidate()
        statusTransitionTimer?.invalidate()

        // Actualiza la ubicación del mensajero cada 3 segundos
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateDriverLocation()
            }
        }

        // Cambia el estado de la orden cada 20 segundos
        statusTransitionTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateOrderStatus()
            }
        }
    }

    private func updateDriverLocation() {
        guard let order = currentOrder,
              let currentDriverLoc = driverLocation else { return }

        let destination = order.deliveryLocation
        let latDiff = (destination.latitude - currentDriverLoc.latitude) * 0.05
        let lonDiff = (destination.longitude - currentDriverLoc.longitude) * 0.05

        let newLocation = CLLocationCoordinate2D(
            latitude: currentDriverLoc.latitude + latDiff,
            longitude: currentDriverLoc.longitude + lonDiff
        )

        driverLocation = newLocation

        // Actualizar tiempo estimado
        if estimatedMinutesRemaining > 0 {
            estimatedMinutesRemaining = max(0, estimatedMinutesRemaining - 1)
        }
    }

    private func updateOrderStatus() {
        switch orderStatus {
        case .idle:
            orderStatus = .confirmed
            estimatedMinutesRemaining = 25
        case .confirmed:
            orderStatus = .preparing
            estimatedMinutesRemaining = 20
        case .preparing:
            orderStatus = .readyForPickup
            estimatedMinutesRemaining = 15
        case .readyForPickup:
            orderStatus = .onTheWay
            estimatedMinutesRemaining = 10
        case .onTheWay:
            orderStatus = .delivered
            estimatedMinutesRemaining = 0
            stopTracking()
        case .delivered, .cancelled:
            stopTracking()
        }
    }

    func stopTracking() {
        timer?.invalidate()
        statusTransitionTimer?.invalidate()
        timer = nil
        statusTransitionTimer = nil
    }

    // Reordenar el último pedido
    func reorderLastOrder() {
        guard let lastOrder = lastOrder else { return }

        let newOrder = WatchOrder(
            id: UUID().uuidString,
            orderNumber: "#\(Int.random(in: 1000...9999))",
            storeName: lastOrder.storeName,
            storeLogoUrl: lastOrder.storeLogoUrl,
            deliveryAddress: lastOrder.deliveryAddress,
            estimatedDeliveryTime: Date().addingTimeInterval(25 * 60),
            items: lastOrder.items,
            total: lastOrder.total,
            status: .confirmed,
            deliveryPerson: lastOrder.deliveryPerson,
            timeline: [],
            storeLocation: lastOrder.storeLocation,
            deliveryLocation: lastOrder.deliveryLocation,
            currentDeliveryLocation: lastOrder.storeLocation
        )

        self.currentOrder = newOrder
        self.orderStatus = .confirmed
        self.driverLocation = lastOrder.storeLocation
        self.estimatedMinutesRemaining = 25

        startTracking()
    }
}

extension WatchOrderStatus {
    static let idle = WatchOrderStatus.confirmed
}
