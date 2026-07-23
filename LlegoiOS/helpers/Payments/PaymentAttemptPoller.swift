import Foundation

/// Poller genérico para proveedores del Grupo A que se confirman por polling
/// (qvapay, usdt, futuro tropipay) en vez de un callback síncrono de SDK.
///
/// Reemplaza los dos bucles casi idénticos que existían antes
/// (startQvaPayPolling/startTronDealerPolling) — misma mecánica exacta
/// (repetir fetchOrder hasta ver `.completed`/`.failed`, o agotar intentos),
/// solo parametrizada. Los callbacks de completado/fallo/timeout se pasan
/// desde el caller porque cada método de pago tiene su propio mensaje y
/// limpieza de UI.
@MainActor
final class PaymentAttemptPoller {
    private var task: Task<Void, Never>?

    private(set) var isPolling = false

    func start(
        config: PaymentPollingConfig,
        fetchOrder: @escaping () async throws -> OrderDetail,
        onUpdate: @escaping (OrderDetail) -> Void,
        onCompleted: @escaping () -> Void,
        onFailed: @escaping () -> Void,
        onTimeout: @escaping () -> Void
    ) {
        stop()
        isPolling = true

        task = Task { [weak self] in
            for attempt in 1...config.maxAttempts {
                if Task.isCancelled {
                    self?.isPolling = false
                    return
                }

                do {
                    let order = try await fetchOrder()
                    onUpdate(order)

                    if order.paymentStatus == .completed {
                        self?.isPolling = false
                        onCompleted()
                        return
                    }

                    if order.paymentStatus == .failed {
                        self?.isPolling = false
                        onFailed()
                        return
                    }
                } catch {
                    print("⚠️ Error en polling de pago (intento \(attempt)): \(error)")
                }

                if attempt < config.maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(config.interval * 1_000_000_000))
                }
            }

            self?.isPolling = false
            onTimeout()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isPolling = false
    }

    deinit {
        task?.cancel()
    }
}
