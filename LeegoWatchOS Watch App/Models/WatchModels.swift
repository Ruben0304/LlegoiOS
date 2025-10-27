//
//  WatchModels.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI
import CoreLocation

// MARK: - Order Models
struct WatchOrder: Identifiable {
    let id: String
    let orderNumber: String
    let storeName: String
    let storeLogoUrl: String
    let deliveryAddress: String
    let estimatedDeliveryTime: Date
    let items: [WatchOrderItem]
    let total: String
    let status: WatchOrderStatus
    let deliveryPerson: WatchDeliveryPerson?
    let timeline: [WatchOrderTimelineEvent]
    let storeLocation: CLLocationCoordinate2D
    let deliveryLocation: CLLocationCoordinate2D
    let currentDeliveryLocation: CLLocationCoordinate2D?
}

struct WatchOrderItem: Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let price: String
    let imageUrl: String
}

struct WatchDeliveryPerson: Identifiable {
    let id: String
    let name: String
    let rating: Double
    let phoneNumber: String
    let vehicleType: String
    let vehiclePlate: String
    let profileImageUrl: String
}

enum WatchOrderStatus: String, CaseIterable {
    case confirmed = "Confirmado"
    case preparing = "Preparando"
    case readyForPickup = "Listo"
    case onTheWay = "En camino"
    case delivered = "Entregado"
    case cancelled = "Cancelado"

    var icon: String {
        switch self {
        case .confirmed: return "checkmark.circle.fill"
        case .preparing: return "timer.circle.fill"
        case .readyForPickup: return "bag.circle.fill"
        case .onTheWay: return "bicycle.circle.fill"
        case .delivered: return "house.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .confirmed: return .llegoAccent
        case .preparing: return .orange
        case .readyForPickup: return .yellow
        case .onTheWay: return .llegoPrimary
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

struct WatchOrderTimelineEvent: Identifiable {
    let id = UUID()
    let status: WatchOrderStatus
    let timestamp: Date
    let message: String
    let isCompleted: Bool
}

// MARK: - Product Models
struct WatchProduct: Identifiable, Hashable {
    let id: Int
    let name: String
    let shop: String
    let weight: String
    let price: String
    let imageUrl: String
}
