import ActivityKit
import Combine
import CoreLocation
import Foundation
import UIKit
import UserNotifications

// MARK: - Delivery Status Enum
enum DeliveryStatus: String, Codable {
    case idle = "idle"
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case inTransit = "in_transit"
    case nearDestination = "near_destination"
    case delivered = "delivered"
    case cancelled = "cancelled"

    var displayText: String {
        switch self {
        case .idle: return "Sin pedido activo"
        case .pending: return "Pedido pendiente"
        case .confirmed: return "Pedido confirmado"
        case .preparing: return "Preparando tu pedido"
        case .inTransit: return "En camino"
        case .nearDestination: return "Cerca de tu ubicación"
        case .delivered: return "Entregado"
        case .cancelled: return "Cancelado"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "cart"
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .preparing: return "flame"
        case .inTransit: return "bicycle"
        case .nearDestination: return "location.circle"
        case .delivered: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Active Order Model
struct ActiveOrder: Codable, Identifiable {
    let id: String
    let products: [OrderProduct]
    let totalAmount: Double
    let currency: String
    let deliveryLocation: String
    let deliveryCoordinates: LocationCoordinate
    let restaurantLocation: String
    let restaurantCoordinates: LocationCoordinate
    let estimatedDeliveryMinutes: Int
    let paymentMethod: String
    let paymentCompleted: Bool
    let createdAt: Date
    var status: DeliveryStatus
    let storeImageUrl: String?
    let userAvatarUrl: String?

    struct OrderProduct: Codable, Identifiable {
        let id: String
        let name: String
        let imageUrl: String
        let quantity: Int
        let price: Double
    }

    struct LocationCoordinate: Codable {
        let latitude: Double
        let longitude: Double

        var clLocationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

// MARK: - Order Manager
@MainActor
class OrderManager: ObservableObject {
    static let shared = OrderManager()

    private struct PersistedActiveOrderState: Codable {
        let order: ActiveOrder
        let orderStatusRaw: String
        let estimatedMinutesRemaining: Int
        let remainingDistanceMeters: Double
        let driverLatitude: Double?
        let driverLongitude: Double?
        let savedAt: Date
    }

    private static let persistedActiveOrderKey = "order_manager.persisted_active_order"

    // Published properties
    @Published var currentOrder: ActiveOrder?
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var estimatedMinutesRemaining: Int = 0
    @Published var orderStatus: DeliveryStatus = .idle
    @Published var remainingDistanceMeters: Double = 0

    // Live Activity
    private var currentActivity: Activity<DeliveryActivityAttributes>?

    // Private properties
    private var timer: Timer?
    private var simulationStartTime: Date?
    private let simulationDuration: TimeInterval = 30  // 30 segundos para prueba rápida
    private var routePoints: [CLLocationCoordinate2D] = []
    private var currentRouteIndex: Int = 0
    private var realtimeSubscriptionTask: Task<Void, Never>?
    private var realtimePollingTask: Task<Void, Never>?
    private var activeRealtimeOrderId: String?
    private let trackingRepository = OrderTrackingRepository()
    private let realtimeClient = OrderTrackingRealtimeClient(baseURL: ApolloClientManager.baseURL)

    private init() {
        requestNotificationPermission()
        restorePersistedActiveOrderIfNeeded()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if granted {
                print("✅ Permisos de notificación otorgados")
            } else {
                print("⚠️ Permisos de notificación NO otorgados")
                if let error = error {
                    print("❌ Error solicitando permisos: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Public Methods

    /// Inicia un nuevo pedido con simulación de 2 minutos
    func startOrder(
        orderId: String? = nil,
        products: [ActiveOrder.OrderProduct],
        totalAmount: Double,
        currency: String,
        deliveryLocation: String,
        deliveryCoordinates: CLLocationCoordinate2D,
        restaurantLocation: String,
        restaurantCoordinates: CLLocationCoordinate2D,
        paymentMethod: String,
        paymentCompleted: Bool = false,
        storeImageUrl: String? = nil,
        userAvatarUrl: String? = nil
    ) {
        // Crear el pedido
        let order = ActiveOrder(
            id: orderId ?? UUID().uuidString,
            products: products,
            totalAmount: totalAmount,
            currency: currency,
            deliveryLocation: deliveryLocation,
            deliveryCoordinates: ActiveOrder.LocationCoordinate(
                latitude: deliveryCoordinates.latitude,
                longitude: deliveryCoordinates.longitude
            ),
            restaurantLocation: restaurantLocation,
            restaurantCoordinates: ActiveOrder.LocationCoordinate(
                latitude: restaurantCoordinates.latitude,
                longitude: restaurantCoordinates.longitude
            ),
            estimatedDeliveryMinutes: 1,  // 30 segundos de simulación
            paymentMethod: paymentMethod,
            paymentCompleted: paymentCompleted,
            createdAt: Date(),
            status: .pending,
            storeImageUrl: storeImageUrl,
            userAvatarUrl: userAvatarUrl
        )

        currentOrder = order
        orderStatus = .pending

        // Generar puntos de la ruta
        generateRoutePoints(
            from: restaurantCoordinates,
            to: deliveryCoordinates
        )

        // Iniciar simulación
        startSimulation()

        // Iniciar Live Activity
        startLiveActivity(for: order)

        print("✅ OrderManager: Pedido iniciado - ID: \(order.id)")
        persistActiveOrderState()
    }

    /// Inicia un pedido real conectado a backend (subscription + polling fallback).
    func startRealtimeOrder(
        orderId: String,
        products: [ActiveOrder.OrderProduct],
        totalAmount: Double,
        currency: String,
        deliveryLocation: String,
        deliveryCoordinates: CLLocationCoordinate2D,
        restaurantLocation: String,
        restaurantCoordinates: CLLocationCoordinate2D,
        paymentMethod: String,
        storeImageUrl: String? = nil,
        userAvatarUrl: String? = nil
    ) {
        stopSimulation()
        stopRealtimeSync()

        let order = ActiveOrder(
            id: orderId,
            products: products,
            totalAmount: totalAmount,
            currency: currency,
            deliveryLocation: deliveryLocation,
            deliveryCoordinates: ActiveOrder.LocationCoordinate(
                latitude: deliveryCoordinates.latitude,
                longitude: deliveryCoordinates.longitude
            ),
            restaurantLocation: restaurantLocation,
            restaurantCoordinates: ActiveOrder.LocationCoordinate(
                latitude: restaurantCoordinates.latitude,
                longitude: restaurantCoordinates.longitude
            ),
            estimatedDeliveryMinutes: 30,
            paymentMethod: paymentMethod,
            paymentCompleted: true,
            createdAt: Date(),
            status: .pending,
            storeImageUrl: storeImageUrl,
            userAvatarUrl: userAvatarUrl
        )

        currentOrder = order
        orderStatus = .pending
        estimatedMinutesRemaining = order.estimatedDeliveryMinutes
        remainingDistanceMeters = 0
        driverLocation = nil
        startLiveActivity(for: order)
        startRealtimeSync(orderId: orderId)

        print("🛰️ OrderManager: Pedido real-time iniciado - ID: \(orderId)")
        persistActiveOrderState()
    }

    /// Detiene el pedido actual
    func stopOrder() {
        stopSimulation()
        stopRealtimeSync()
        endLiveActivity()
        currentOrder = nil
        driverLocation = nil
        orderStatus = .idle
        estimatedMinutesRemaining = 0
        remainingDistanceMeters = 0
        print("⏹️ OrderManager: Pedido detenido")
        clearPersistedActiveOrderState()
    }

    /// Cancela el pedido actual
    func cancelOrder() {
        guard var order = currentOrder else { return }

        order.status = .cancelled
        currentOrder = order
        orderStatus = .cancelled

        stopSimulation()
        stopRealtimeSync()
        endLiveActivity()

        print("❌ OrderManager: Pedido cancelado - ID: \(order.id)")
        clearPersistedActiveOrderState()
    }

    // MARK: - Private Methods

    private func startSimulation() {
        simulationStartTime = Date()
        currentRouteIndex = 0

        // Mantener "pending" al inicio para que el accessory muestre estado de pedido
        estimatedMinutesRemaining = 1

        // Iniciar ubicación del conductor en el restaurante
        if let order = currentOrder {
            driverLocation = order.restaurantCoordinates.clLocationCoordinate
        }

        // Timer que se ejecuta cada 1 segundo (30 updates en 30 segundos)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSimulation()
            }
        }

        print("▶️ OrderManager: Simulación iniciada")
    }

    private func startRealtimeSync(orderId: String) {
        activeRealtimeOrderId = orderId

        realtimeSubscriptionTask = Task { [weak self] in
            guard let self else { return }
            guard let jwt = AuthManager.shared.getAccessToken() else { return }

            do {
                try await self.realtimeClient.streamOrderUpdates(orderId: orderId, jwt: jwt) { [weak self] event in
                    await MainActor.run {
                        self?.applyRealtimeEvent(event)
                    }
                }
            } catch {
                print("⚠️ Subscription order-tracking desconectada: \(error.localizedDescription)")
            }
        }

        realtimePollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refreshTrackingSnapshot(orderId: orderId)
                try? await Task.sleep(nanoseconds: 6_000_000_000)
            }
        }
    }

    private func stopRealtimeSync() {
        realtimeSubscriptionTask?.cancel()
        realtimeSubscriptionTask = nil
        realtimePollingTask?.cancel()
        realtimePollingTask = nil
        activeRealtimeOrderId = nil
    }

    private func refreshTrackingSnapshot(orderId: String) async {
        guard activeRealtimeOrderId == orderId else { return }
        let result = await withCheckedContinuation { continuation in
            trackingRepository.fetchTracking(orderId: orderId) { fetchResult in
                continuation.resume(returning: fetchResult)
            }
        }

        switch result {
        case .success(let tracking):
            applyTrackingSnapshot(tracking)
        case .failure(let error):
            print("ℹ️ Polling tracking fallo (se reintentará): \(error.localizedDescription)")
        }
    }

    private func applyTrackingSnapshot(_ tracking: OrderTracking) {
        guard let existingOrder = currentOrder, tracking.order.id == existingOrder.id else { return }

        driverLocation = tracking.deliveryPersonLocation
        if let km = tracking.distanceKm {
            remainingDistanceMeters = max(0, km * 1000)
        } else {
            updateRemainingDistance()
        }
        estimatedMinutesRemaining = tracking.estimatedMinutes ?? estimatedMinutesRemaining

        let mappedStatus = mapGraphQLStatusToDeliveryStatus(tracking.order.status, distanceKm: tracking.distanceKm)
        if mappedStatus != orderStatus {
            orderStatus = mappedStatus
            currentOrder?.status = mappedStatus
            updateLiveActivity(progress: progressValue(for: mappedStatus))
            if mappedStatus == .delivered {
                sendDeliveryNotification()
                endLiveActivity(delivered: true)
                stopRealtimeSync()
                clearPersistedActiveOrderState()
            } else if mappedStatus == .cancelled {
                endLiveActivity(delivered: false)
                stopRealtimeSync()
                clearPersistedActiveOrderState()
            } else {
                persistActiveOrderState()
            }
        } else {
            updateLiveActivity(progress: progressValue(for: mappedStatus))
            persistActiveOrderState()
        }
    }

    private func applyRealtimeEvent(_ event: OrderTrackingRealtimeEvent) {
        guard let existingOrder = currentOrder, existingOrder.id == event.orderId else { return }

        if let coords = event.deliveryPersonCoordinates, coords.count >= 2 {
            driverLocation = CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
        }
        if let km = event.distanceKm {
            remainingDistanceMeters = max(0, km * 1000)
        }
        if let estimated = event.estimatedMinutes {
            estimatedMinutesRemaining = estimated
        }

        guard let statusRaw = event.statusRaw else {
            updateLiveActivity(progress: progressValue(for: orderStatus))
            return
        }

        let mappedStatus = mapRawStatusToDeliveryStatus(statusRaw, distanceKm: event.distanceKm)
        if mappedStatus != orderStatus {
            orderStatus = mappedStatus
            currentOrder?.status = mappedStatus
            if mappedStatus == .delivered {
                sendDeliveryNotification()
                endLiveActivity(delivered: true)
                stopRealtimeSync()
                clearPersistedActiveOrderState()
            } else if mappedStatus == .cancelled {
                endLiveActivity(delivered: false)
                stopRealtimeSync()
                clearPersistedActiveOrderState()
            } else {
                persistActiveOrderState()
            }
        }
        updateLiveActivity(progress: progressValue(for: mappedStatus))
        if mappedStatus != .delivered && mappedStatus != .cancelled {
            persistActiveOrderState()
        }
    }

    private func progressValue(for status: DeliveryStatus) -> Double {
        switch status {
        case .idle, .pending:
            return 0.05
        case .confirmed:
            return 0.2
        case .preparing:
            return 0.45
        case .inTransit:
            return 0.75
        case .nearDestination:
            return 0.9
        case .delivered:
            return 1.0
        case .cancelled:
            return 0.0
        }
    }

    private func mapGraphQLStatusToDeliveryStatus(_ status: OrderStatusEnum, distanceKm: Double?) -> DeliveryStatus {
        switch status {
        case .pendingAcceptance, .modifiedByStore:
            return .pending
        case .accepted:
            return .confirmed
        case .preparing:
            return .preparing
        case .readyForPickup:
            return .inTransit
        case .onTheWay:
            if let distanceKm, distanceKm <= 0.35 {
                return .nearDestination
            }
            return .inTransit
        case .delivered:
            return .delivered
        case .cancelled:
            return .cancelled
        }
    }

    private func mapRawStatusToDeliveryStatus(_ rawStatus: String, distanceKm: Double?) -> DeliveryStatus {
        switch rawStatus.uppercased() {
        case "PENDING_ACCEPTANCE", "MODIFIED_BY_STORE":
            return .pending
        case "ACCEPTED":
            return .confirmed
        case "PREPARING":
            return .preparing
        case "READY_FOR_PICKUP":
            return .inTransit
        case "ON_THE_WAY":
            if let distanceKm, distanceKm <= 0.35 {
                return .nearDestination
            }
            return .inTransit
        case "DELIVERED":
            return .delivered
        case "CANCELLED":
            return .cancelled
        default:
            return orderStatus
        }
    }

    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
        simulationStartTime = nil
        currentRouteIndex = 0
        routePoints.removeAll()
    }

    private func updateSimulation() {
        guard let startTime = simulationStartTime,
            let order = currentOrder
        else {
            stopSimulation()
            return
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let progress = min(elapsedTime / simulationDuration, 1.0)

        // Actualizar tiempo restante
        let remainingSeconds = max(0, simulationDuration - elapsedTime)
        estimatedMinutesRemaining = Int(ceil(remainingSeconds / 60.0))

        // Actualizar estado según el progreso
        updateOrderStatus(progress: progress)

        // Actualizar ubicación del conductor y distancia restante
        updateDriverLocation(progress: progress)
        updateRemainingDistance()

        // Actualizar Live Activity
        updateLiveActivity(progress: progress)

        // Verificar si se completó la simulación
        if progress >= 1.0 {
            completeOrder()
        }
    }

    private func updateOrderStatus(progress: Double) {
        let newStatus: DeliveryStatus

        switch progress {
        case 0.0..<0.2:
            newStatus = .confirmed
        case 0.2..<0.4:
            newStatus = .preparing
        case 0.4..<0.85:
            newStatus = .inTransit
        case 0.85..<1.0:
            newStatus = .nearDestination
        default:
            newStatus = .delivered
        }

        if newStatus != orderStatus {
            orderStatus = newStatus
            currentOrder?.status = newStatus
            print("📍 OrderManager: Estado actualizado - \(newStatus.displayText)")
        }
    }

    private func updateDriverLocation(progress: Double) {
        guard !routePoints.isEmpty else { return }

        let targetIndex = Int(Double(routePoints.count - 1) * progress)
        let clampedIndex = min(max(targetIndex, 0), routePoints.count - 1)

        // Interpolación suave entre puntos
        if clampedIndex < routePoints.count - 1 {
            let currentPoint = routePoints[clampedIndex]
            let nextPoint = routePoints[clampedIndex + 1]

            let segmentProgress = (Double(routePoints.count - 1) * progress) - Double(clampedIndex)

            let interpolatedLat =
                currentPoint.latitude + (nextPoint.latitude - currentPoint.latitude)
                * segmentProgress
            let interpolatedLon =
                currentPoint.longitude + (nextPoint.longitude - currentPoint.longitude)
                * segmentProgress

            driverLocation = CLLocationCoordinate2D(
                latitude: interpolatedLat,
                longitude: interpolatedLon
            )
        } else {
            driverLocation = routePoints[clampedIndex]
        }

        currentRouteIndex = clampedIndex
    }

    private func updateRemainingDistance() {
        guard let driver = driverLocation, let order = currentOrder else {
            remainingDistanceMeters = 0
            return
        }
        let destination = order.deliveryCoordinates.clLocationCoordinate
        let driverCL = CLLocation(latitude: driver.latitude, longitude: driver.longitude)
        let destCL = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        remainingDistanceMeters = driverCL.distance(from: destCL)
    }

    private func completeOrder() {
        guard var order = currentOrder else { return }

        order.status = .delivered
        currentOrder = order
        orderStatus = .delivered
        estimatedMinutesRemaining = 0
        remainingDistanceMeters = 0

        stopSimulation()

        // Finalizar Live Activity con estado entregado
        endLiveActivity(delivered: true)

        // Enviar notificación
        sendDeliveryNotification()

        print("✅ OrderManager: Pedido entregado - ID: \(order.id)")
        clearPersistedActiveOrderState()
    }

    private func sendDeliveryNotification() {
        print("🔔 Intentando enviar notificación de entrega...")

        let content = UNMutableNotificationContent()
        content.title = "¡Tu pedido ha llegado! 🎉"
        content.body = "El mensajero está en tu puerta. ¡Disfruta tu pedido!"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación: \(error.localizedDescription)")
            } else {
                print("✅ Notificación de entrega enviada correctamente")
            }
        }
    }

    // MARK: - Live Activity Management

    private func startLiveActivity(for order: ActiveOrder) {
        Task { [weak self] in
            await self?.startLiveActivityAsync(for: order)
        }
    }

    private func startLiveActivityAsync(for order: ActiveOrder) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities no están habilitadas")
            return
        }

        let initialState = DeliveryActivityAttributes.ContentState(
            status: orderStatus.rawValue,
            statusDisplayText: orderStatus.displayText,
            statusIcon: orderStatus.icon,
            progressValue: 0.0,
            remainingDistance: formattedRemainingDistance,
            estimatedMinutes: estimatedMinutesRemaining
        )

        let storeImageDataLarge = await fetchThumbnailData(
            from: order.storeImageUrl, maxSide: 28, maxBytes: 1800)
        let storeImageDataSmall = await fetchThumbnailData(
            from: order.storeImageUrl, maxSide: 18, maxBytes: 700)
        let userAvatarDataSmall = await fetchThumbnailData(
            from: order.userAvatarUrl, maxSide: 16, maxBytes: 500)

        print(
            "🖼️ LiveActivity payload images storeLarge=\(storeImageDataLarge?.count ?? 0)B storeSmall=\(storeImageDataSmall?.count ?? 0)B userSmall=\(userAvatarDataSmall?.count ?? 0)B"
        )

        // Intento 1: logo tienda (prioridad) + avatar usuario.
        var attributes = DeliveryActivityAttributes(
            orderID: order.id,
            storeName: trimmedForActivity(order.restaurantLocation, max: 56),
            storeIcon: "storefront.fill",
            storeImageUrl: order.storeImageUrl,
            userAvatarUrl: order.userAvatarUrl,
            storeImageData: storeImageDataLarge,
            userAvatarData: userAvatarDataSmall,
            totalAmount: "\(order.currency) \(String(format: "%.2f", order.totalAmount))",
            deliveryAddress: trimmedForActivity(order.deliveryLocation, max: 72)
        )

        if let activity = tryRequestLiveActivity(attributes: attributes, state: initialState) {
            currentActivity = activity
            print("🟢 Live Activity iniciada (logo + avatar): \(activity.id)")
            return
        }

        // Intento 2: solo logo de tienda en tamaño pequeño.
        attributes = DeliveryActivityAttributes(
            orderID: order.id,
            storeName: trimmedForActivity(order.restaurantLocation, max: 48),
            storeIcon: "storefront.fill",
            storeImageUrl: order.storeImageUrl,
            userAvatarUrl: order.userAvatarUrl,
            storeImageData: storeImageDataSmall,
            userAvatarData: nil,
            totalAmount: "\(order.currency) \(String(format: "%.2f", order.totalAmount))",
            deliveryAddress: trimmedForActivity(order.deliveryLocation, max: 60)
        )
        if let activity = tryRequestLiveActivity(attributes: attributes, state: initialState) {
            currentActivity = activity
            print("🟢 Live Activity iniciada (solo logo tienda): \(activity.id)")
            return
        }

        // Intento 3: payload mínimo sin imágenes.
        attributes = DeliveryActivityAttributes(
            orderID: order.id,
            storeName: trimmedForActivity(order.restaurantLocation, max: 36),
            storeIcon: "storefront.fill",
            storeImageUrl: order.storeImageUrl,
            userAvatarUrl: order.userAvatarUrl,
            storeImageData: nil,
            userAvatarData: nil,
            totalAmount: "\(order.currency) \(String(format: "%.2f", order.totalAmount))",
            deliveryAddress: trimmedForActivity(order.deliveryLocation, max: 48)
        )
        if let activity = tryRequestLiveActivity(attributes: attributes, state: initialState) {
            currentActivity = activity
            print("🟢 Live Activity iniciada (sin imágenes fallback): \(activity.id)")
            return
        }

        print(
            "❌ Error iniciando Live Activity: todos los intentos fallaron por tamaño u otro error")
    }

    private func tryRequestLiveActivity(
        attributes: DeliveryActivityAttributes,
        state: DeliveryActivityAttributes.ContentState
    ) -> Activity<DeliveryActivityAttributes>? {
        do {
            return try Activity<DeliveryActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("⚠️ Live Activity request falló: \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchThumbnailData(from urlString: String?, maxSide: CGFloat, maxBytes: Int) async
        -> Data?
    {
        guard
            let urlString,
            !urlString.isEmpty,
            let url = URL(string: urlString)
        else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            if let token = AuthManager.shared.getAccessToken(), !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await URLSession.shared.data(for: request)
            guard
                let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                let image = UIImage(data: data)
            else {
                return nil
            }

            let resized = resizeImage(image, maxSide: maxSide)
            guard var compressed = resized.jpegData(compressionQuality: 0.45) else {
                return nil
            }
            if compressed.count > maxBytes {
                guard let smaller = resized.jpegData(compressionQuality: 0.25) else {
                    return nil
                }
                compressed = smaller
            }
            return compressed.count <= maxBytes ? compressed : nil
        } catch {
            return nil
        }
    }

    private func resizeImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let scale = min(maxSide / size.width, maxSide / size.height, 1.0)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func trimmedForActivity(_ value: String, max: Int) -> String {
        guard value.count > max else { return value }
        let index = value.index(value.startIndex, offsetBy: max)
        return String(value[..<index])
    }

    private func updateLiveActivity(progress: Double) {
        guard let activity = currentActivity else { return }

        let updatedState = DeliveryActivityAttributes.ContentState(
            status: orderStatus.rawValue,
            statusDisplayText: orderStatus.displayText,
            statusIcon: orderStatus.icon,
            progressValue: progress,
            remainingDistance: formattedRemainingDistance,
            estimatedMinutes: estimatedMinutesRemaining
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    private func persistActiveOrderState() {
        guard let order = currentOrder else {
            clearPersistedActiveOrderState()
            return
        }
        guard Calendar.current.isDateInToday(order.createdAt) else {
            clearPersistedActiveOrderState()
            return
        }
        guard orderStatus != .delivered, orderStatus != .cancelled, orderStatus != .idle else {
            clearPersistedActiveOrderState()
            return
        }

        let snapshot = PersistedActiveOrderState(
            order: order,
            orderStatusRaw: orderStatus.rawValue,
            estimatedMinutesRemaining: estimatedMinutesRemaining,
            remainingDistanceMeters: remainingDistanceMeters,
            driverLatitude: driverLocation?.latitude,
            driverLongitude: driverLocation?.longitude,
            savedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: Self.persistedActiveOrderKey)
        } catch {
            print("⚠️ No se pudo persistir pedido activo: \(error.localizedDescription)")
        }
    }

    private func restorePersistedActiveOrderIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistedActiveOrderKey) else {
            return
        }

        do {
            let snapshot = try JSONDecoder().decode(PersistedActiveOrderState.self, from: data)
            guard Calendar.current.isDateInToday(snapshot.order.createdAt) else {
                clearPersistedActiveOrderState()
                return
            }

            let restoredStatus = DeliveryStatus(rawValue: snapshot.orderStatusRaw) ?? snapshot.order.status
            guard restoredStatus != .delivered, restoredStatus != .cancelled, restoredStatus != .idle else {
                clearPersistedActiveOrderState()
                return
            }

            currentOrder = snapshot.order
            orderStatus = restoredStatus
            estimatedMinutesRemaining = snapshot.estimatedMinutesRemaining
            remainingDistanceMeters = snapshot.remainingDistanceMeters
            if let lat = snapshot.driverLatitude, let lon = snapshot.driverLongitude {
                driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else {
                driverLocation = nil
            }

            startRealtimeSync(orderId: snapshot.order.id)
        } catch {
            clearPersistedActiveOrderState()
            print("⚠️ No se pudo restaurar pedido persistido: \(error.localizedDescription)")
        }
    }

    private func clearPersistedActiveOrderState() {
        UserDefaults.standard.removeObject(forKey: Self.persistedActiveOrderKey)
    }

    private func endLiveActivity(delivered: Bool = false) {
        guard let activity = currentActivity else { return }

        let finalState = DeliveryActivityAttributes.ContentState(
            status: delivered
                ? DeliveryStatus.delivered.rawValue : DeliveryStatus.cancelled.rawValue,
            statusDisplayText: delivered ? "¡Entregado!" : "Cancelado",
            statusIcon: delivered ? "checkmark.seal.fill" : "xmark.circle",
            progressValue: delivered ? 1.0 : 0.0,
            remainingDistance: delivered ? "Llegó" : "--",
            estimatedMinutes: 0
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + 60)
            )
            print("🔴 Live Activity finalizada (delivered: \(delivered))")
        }

        currentActivity = nil
    }

    /// Distancia restante formateada para la Live Activity
    private var formattedRemainingDistance: String {
        let meters = remainingDistanceMeters
        if meters <= 0 { return "Llegó" }
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    // MARK: - Route Generation

    private func generateRoutePoints(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) {
        routePoints.removeAll()

        // Número de puntos intermedios (más puntos = movimiento más suave)
        let numberOfPoints = 40

        // Generar ruta con variación realista (no línea recta)
        for i in 0...numberOfPoints {
            let progress = Double(i) / Double(numberOfPoints)

            // Interpolación base
            let baseLat = start.latitude + (end.latitude - start.latitude) * progress
            let baseLon = start.longitude + (end.longitude - start.longitude) * progress

            // Añadir variación sinusoidal para simular calles (no línea recta)
            let variation = sin(progress * .pi * 3) * 0.0005  // Variación pequeña

            let adjustedLat = baseLat + variation
            let adjustedLon = baseLon + variation * 0.7

            let point = CLLocationCoordinate2D(
                latitude: adjustedLat,
                longitude: adjustedLon
            )

            routePoints.append(point)
        }

        print("🗺️ OrderManager: Ruta generada con \(routePoints.count) puntos")
    }
}

// MARK: - Helper Extensions

extension OrderManager {
    /// Obtiene un pedido de ejemplo para testing
    static func createMockOrder() -> ActiveOrder {
        ActiveOrder(
            id: UUID().uuidString,
            products: [
                ActiveOrder.OrderProduct(
                    id: "1",
                    name: "Pizza Margarita",
                    imageUrl:
                        "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen PNG.png",
                    quantity: 2,
                    price: 15.50
                ),
                ActiveOrder.OrderProduct(
                    id: "2",
                    name: "Tres Leches",
                    imageUrl:
                        "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (13).png",
                    quantity: 1,
                    price: 8.00
                ),
                ActiveOrder.OrderProduct(
                    id: "3",
                    name: "Batido de Mamey",
                    imageUrl:
                        "https://bucket-production-435ad.up.railway.app:443/products-assets/Imagen (17).png",
                    quantity: 1,
                    price: 5.00
                ),
            ],
            totalAmount: 45.50,
            currency: "USD",
            deliveryLocation: "Calle 23 #456, Vedado, La Habana",
            deliveryCoordinates: ActiveOrder.LocationCoordinate(
                latitude: 23.1136,
                longitude: -82.3666
            ),
            restaurantLocation: "Restaurante El Cubano, Centro Habana",
            restaurantCoordinates: ActiveOrder.LocationCoordinate(
                latitude: 23.1150,
                longitude: -82.3680
            ),
            estimatedDeliveryMinutes: 2,
            paymentMethod: "Efectivo CUP",
            paymentCompleted: true,
            createdAt: Date(),
            status: .pending,
            storeImageUrl:
                "https://bucket-production-435ad.up.railway.app:443/branches-assets/branch-avatar.png",
            userAvatarUrl: AuthManager.shared.currentUser?.avatarUrl
        )
    }
}
