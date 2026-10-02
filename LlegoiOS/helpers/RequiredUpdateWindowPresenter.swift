import Combine
import SwiftUI
import UIKit

/// Presenta la actualización obligatoria en una ventana propia, por encima de toda la app.
///
/// El overlay que vive dentro de `MainAppView` queda por debajo de cualquier hoja
/// (carrito, filtros...) y de los `fullScreenCover` (detalle de pedido abierto desde
/// una push en frío), así que con una de esas pantallas abiertas el usuario con una
/// versión < `minVersion` podía seguir usando la app. Una `UIWindow` con nivel
/// `.alert + 1` siempre queda encima de lo que haya presentado SwiftUI.
///
/// Solo se usa para `UpdateType.required`: la opcional y el mantenimiento se pueden
/// descartar y siguen siendo un overlay normal.
@MainActor
final class RequiredUpdateWindowPresenter: ObservableObject {
    static let shared = RequiredUpdateWindowPresenter()

    /// true cuando hay una actualización obligatoria pendiente pero no se pudo crear la
    /// ventana (aún no hay escena de UIKit). Mientras tanto `MainAppView` pinta el overlay
    /// normal como respaldo, para que la pantalla bloqueante nunca desaparezca.
    @Published private(set) var needsInlineFallback = false

    private var window: UIWindow?
    private var wantsToShow = false
    private var started = false
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    /// Empieza a observar al view model. Es idempotente.
    func start(viewModel: AppUpdateViewModel = .shared) {
        guard !started else { return }
        started = true

        // `showUpdateAlert` y `updateType` se asignan por separado: se combinan y se
        // procesan en el siguiente ciclo para ver siempre el par ya consistente.
        Publishers.CombineLatest(viewModel.$showUpdateAlert, viewModel.$updateType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showAlert, updateType in
                self?.wantsToShow = showAlert && updateType == .required
                self?.refresh(viewModel: viewModel)
            }
            .store(in: &cancellables)

        // Si la escena aún no estaba lista cuando llegó la orden de bloquear, reintenta
        // en cuanto una escena se active.
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh(viewModel: viewModel)
            }
            .store(in: &cancellables)
    }

    // MARK: - Ventana

    private func refresh(viewModel: AppUpdateViewModel) {
        if wantsToShow {
            present(viewModel: viewModel)
        } else {
            dismiss()
        }
    }

    private func present(viewModel: AppUpdateViewModel) {
        guard window == nil else { return }
        guard let scene = activeScene() else {
            needsInlineFallback = true
            return
        }

        let host = UIHostingController(rootView: AppUpdateModal(viewModel: viewModel))
        host.view.backgroundColor = .clear

        let newWindow = UIWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1
        newWindow.backgroundColor = .clear
        // La app fuerza el modo claro desde la raíz (`iOSApp`); esta ventana queda fuera
        // de esa jerarquía y hay que forzarlo aquí para que el modal se vea igual.
        newWindow.overrideUserInterfaceStyle = .light
        newWindow.rootViewController = host
        newWindow.alpha = 0
        newWindow.makeKeyAndVisible()
        UIView.animate(withDuration: 0.3) { newWindow.alpha = 1 }

        window = newWindow
        needsInlineFallback = false
    }

    private func dismiss() {
        needsInlineFallback = false
        guard let oldWindow = window else { return }
        window = nil

        let scene = oldWindow.windowScene
        UIView.animate(
            withDuration: 0.3,
            animations: { oldWindow.alpha = 0 },
            completion: { _ in
                oldWindow.isHidden = true
                oldWindow.rootViewController = nil
                // Devolver el foco a la ventana principal de la app.
                scene?.windows.first { $0 !== oldWindow && !$0.isHidden }?.makeKey()
            }
        )
    }

    private func activeScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
    }
}
