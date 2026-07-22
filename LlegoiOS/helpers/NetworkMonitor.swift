import Foundation
import Network
import Combine

/// Señal única y compartida de conectividad real del dispositivo (NWPathMonitor).
/// Cualquier pantalla que necesite saber si hay red debe leer `isConnected` en
/// vez de implementar su propio chequeo (HEAD request, NWPathMonitor propio, etc.).
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.llego.networkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
