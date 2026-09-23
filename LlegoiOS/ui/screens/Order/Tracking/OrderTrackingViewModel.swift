import Combine
import CoreLocation
import Foundation

@MainActor
final class OrderTrackingViewModel: ObservableObject {
    @Published var tracking: OrderTracking?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var currentDeliveryLocation: CLLocationCoordinate2D?
    @Published var estimatedMinutesRemaining: Int?

    private let repository = OrderTrackingRepository()
    private let orderId: String
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(orderId: String) {
        self.orderId = orderId
        load()
        startPolling()
    }

    // MARK: - Load Tracking

    func load() {
        isLoading = tracking == nil
        errorMessage = nil

        repository.fetchTracking(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let trackingData):
                    self.tracking = trackingData
                    self.currentDeliveryLocation = trackingData.deliveryPersonLocation
                    self.estimatedMinutesRemaining = trackingData.estimatedMinutes

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Polling for Real-time Updates

    func startPolling() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.refreshTracking()
            }
        }
    }

    func stopPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func refreshTracking() {
        guard let status = tracking?.order.status,
            status.normalizedForContract == .onTheWay
                || status.normalizedForContract == .readyForPickup
                || status.normalizedForContract == .preparing
        else {
            return
        }

        repository.fetchTracking(orderId: orderId) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let trackingData):
                    self.currentDeliveryLocation = trackingData.deliveryPersonLocation
                    self.estimatedMinutesRemaining = trackingData.estimatedMinutes

                    if self.tracking?.order.status != trackingData.order.status {
                        self.tracking = trackingData
                    }

                case .failure:
                    break
                }
            }
        }
    }

    // MARK: - Computed Properties

    var order: OrderTrackingOrder? {
        tracking?.order
    }

    var deliveryPerson: OrderDeliveryPerson? {
        tracking?.order.deliveryPerson
    }

    var timeline: [OrderTimelineEvent] {
        tracking?.order.timeline ?? []
    }

    var storeLocation: CLLocationCoordinate2D? {
        tracking.flatMap { $0.storeLocation }
    }

    var deliveryLocation: CLLocationCoordinate2D? {
        tracking.flatMap { $0.deliveryLocation }
    }

    var routePolyline: String? {
        tracking?.routePolyline
    }

    var isDeliveryInProgress: Bool {
        tracking?.order.status.normalizedForContract == .onTheWay
    }

    var isPickupOrder: Bool {
        tracking?.order.isPickup == true
    }

    var showDeliveryPersonOnMap: Bool {
        isDeliveryInProgress && currentDeliveryLocation != nil
    }

    var formattedETA: String {
        guard let minutes = estimatedMinutesRemaining else { return "--" }
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }

    var formattedDistance: String {
        guard let km = tracking?.distanceKm else { return "--" }
        if km < 1 {
            return "\(Int(km * 1000)) m"
        } else {
            return String(format: "%.1f km", km)
        }
    }
}
