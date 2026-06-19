import SwiftUI
import SceneKit

// MARK: - Carousel slot definition
/// Los 4 modelos se distribuyen en un círculo horizontal (estilo tiovivo) en el plano XZ.
/// `baseAngle = index * 90°`, medido desde +Z (frente, hacia la cámara).
/// Orden de aparición y de explicación: 0 → 1 → 2 → 3.
fileprivate struct CarouselSlot {
    let name: String
    let index: Int            // 0=restaurant, 1=mercadito, 2=dulce, 3=perfume
    let customScale: Float?
    let selfOscillation: Double
}

private let carouselSlots: [CarouselSlot] = [
    CarouselSlot(name: "restaurant", index: 0, customScale: nil,  selfOscillation: 6.0),
    CarouselSlot(name: "mercadito",  index: 1, customScale: nil,  selfOscillation: 5.4),
    CarouselSlot(name: "dulce",      index: 2, customScale: 0.85, selfOscillation: 6.6),
    CarouselSlot(name: "perfume",    index: 3, customScale: 0.95, selfOscillation: 7.2),
]

// MARK: - Tunables
/// Ajustables visualmente: si el anillo queda muy alto/bajo o muy grande, toca aquí.
private enum CarouselConfig {
    static let radius: Float = 2.0                 // radio del círculo (más estrecho → no se sale de pantalla)
    static let cameraPosition = SCNVector3(0, 6.2, 8.5)
    static let cameraPitch: Float = -0.42          // rad (~ -24°): perspectiva aún más alta → anillo más circular
    static let fieldOfView: CGFloat = 58
    static let carouselY: Float = 2.9              // altura del anillo (sube los modelos en pantalla)
    static let modelNormalizedSize: Float = 1.4    // tamaño objetivo de cada modelo (más chicos)
    static let focusScaleMultiplier: Float = 1.22  // énfasis del modelo al frente
    static let dimmedScaleMultiplier: Float = 0.9
    static let dimmedOpacity: CGFloat = 0.28
    static let idleSpinDuration: Double = 34.0     // segundos por vuelta completa (giro suave)
}

// MARK: - View

struct OnboardingScene3DView: UIViewRepresentable {
    let triggerExit: Bool
    let isHoldVibrating: Bool
    let modelsVisible: Bool       // false = invisible, true = animan su entrada
    let highlightedIndex: Int?    // nil = sin foco; 0-3 = ese modelo al frente
    let cinematicFinished: Bool   // true = estado de reposo (giro continuo suave)
    let exitHandoffScale: CGFloat // factor de tamaño del Home, bakeado en la escala del modelo al salir
    let onExitComplete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onExitComplete: onExitComplete) }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling2X
        sceneView.preferredFramesPerSecond = 0
        sceneView.allowsCameraControl = false

        let scene = SCNScene()
        let coord = context.coordinator
        coord.sceneView = sceneView

        // Nodo carrusel: gira en Y para orbitar todos los modelos a la vez.
        let carousel = SCNNode()
        carousel.position = SCNVector3(0, CarouselConfig.carouselY, 0)
        scene.rootNode.addChildNode(carousel)
        coord.carouselNode = carousel

        // Cámara elevada y picada → el círculo se lee como un anillo.
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.fieldOfView = CarouselConfig.fieldOfView
        cam.camera?.zNear = 0.1
        cam.camera?.zFar = 150
        cam.position = CarouselConfig.cameraPosition
        cam.eulerAngles = SCNVector3(CarouselConfig.cameraPitch, 0, 0)
        scene.rootNode.addChildNode(cam)
        coord.cameraNode = cam

        sceneView.scene = scene

        // Restaurante síncrono (héroe), resto en background sin bloquear la UI.
        coord.loadModel(slot: carouselSlots[0], into: carousel)
        for slot in carouselSlots.dropFirst() {
            coord.loadModelAsync(slot: slot, into: carousel)
        }
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let coord = context.coordinator
        coord.exitHandoffScale = Float(exitHandoffScale)

        // Exit animation
        if triggerExit && !coord.exitTriggered {
            coord.exitTriggered = true
            coord.runExitAnimation()
        }

        // Hold vibration
        coord.setHoldVibrating(isHoldVibrating)

        // Models appear (forman el círculo)
        if modelsVisible && !coord.modelsAreVisible {
            coord.modelsAreVisible = true
            coord.animateModelsIn()
        }

        // Foco en un modelo (pausa el giro + lo trae al frente)
        if highlightedIndex != coord.currentHighlight {
            coord.currentHighlight = highlightedIndex
            if let idx = highlightedIndex { coord.focusModel(idx) }
        }

        // Estado de reposo: reanuda el giro continuo suave por la circunferencia
        if cinematicFinished && !coord.restingStarted {
            coord.restingStarted = true
            coord.enterRestingState()
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject {
        var sceneView: SCNView?
        var cameraNode: SCNNode?
        var carouselNode: SCNNode?
        var holderNodes: [Int: SCNNode] = [:]   // nodo posicionado en el círculo (hijo del carrusel)
        var modelNodes: [Int: SCNNode] = [:]    // modelo dentro de su holder
        var normalScales: [Int: Float] = [:]
        var exitTriggered = false
        var modelsAreVisible = false
        var restingStarted = false
        var currentHighlight: Int? = -99        // sentinel para forzar la primera actualización
        var isCurrentlyVibrating = false
        var exitHandoffScale: Float = 1         // factor de tamaño del Home (se setea desde updateUIView)
        let onExitComplete: () -> Void

        private struct SceneBox: @unchecked Sendable { let scene: SCNScene? }

        init(onExitComplete: @escaping () -> Void) {
            self.onExitComplete = onExitComplete
        }

        // MARK: Geometría del círculo

        private func baseAngle(_ index: Int) -> Float { Float(index) * (.pi / 2) }

        private func circlePosition(_ index: Int) -> SCNVector3 {
            let a = Double(baseAngle(index))
            let r = Double(CarouselConfig.radius)
            return SCNVector3(Float(r * sin(a)), 0, Float(r * cos(a)))
        }

        /// Rotación del carrusel (eje Y) que deja el modelo `index` al frente (hacia la cámara).
        /// Negativa y monótona (0, -90°, -180°, -270°) → giro siempre en el mismo sentido.
        private func frontRotation(for index: Int) -> Float { -baseAngle(index) }

        private func idleSpinAction() -> SCNAction {
            SCNAction.repeatForever(
                .rotateBy(x: 0, y: -2 * .pi, z: 0, duration: CarouselConfig.idleSpinDuration)
            )
        }

        // MARK: Loading

        fileprivate func loadModel(slot: CarouselSlot, into carousel: SCNNode) {
            let key = slot.name
            if let cached = MultiModel3DCarouselView.sceneCache[key] {
                addNode(from: cached, slot: slot, into: carousel); return
            }
            guard let url = Bundle.main.url(forResource: key, withExtension: "usdz"),
                  let loaded = try? SCNScene(url: url, options: nil) else { return }
            MultiModel3DCarouselView.sceneCache[key] = loaded
            addNode(from: loaded, slot: slot, into: carousel)
        }

        fileprivate func loadModelAsync(slot: CarouselSlot, into carousel: SCNNode) {
            let key = slot.name
            if let cached = MultiModel3DCarouselView.sceneCache[key] {
                addNode(from: cached, slot: slot, into: carousel); return
            }
            guard let url = Bundle.main.url(forResource: key, withExtension: "usdz") else { return }
            Task { [weak self] in
                let box = await withCheckedContinuation { (c: CheckedContinuation<SceneBox, Never>) in
                    DispatchQueue.global(qos: .utility).async {
                        c.resume(returning: SceneBox(scene: try? SCNScene(url: url, options: nil)))
                    }
                }
                guard let loaded = box.scene, let self else { return }
                MultiModel3DCarouselView.sceneCache[key] = loaded
                self.addNode(from: loaded, slot: slot, into: carousel)
            }
        }

        private func addNode(from modelScene: SCNScene, slot: CarouselSlot, into carousel: SCNNode) {
            guard holderNodes[slot.index] == nil else { return }

            // Holder fijo en la circunferencia; el modelo vive dentro y se centra en él.
            let holder = SCNNode()
            holder.position = circlePosition(slot.index)

            let node = modelScene.rootNode.clone()
            let (minB, maxB) = node.boundingBox
            let size = SCNVector3(maxB.x - minB.x, maxB.y - minB.y, maxB.z - minB.z)
            let maxDim = max(size.x, max(size.y, size.z))
            let finalScale = (CarouselConfig.modelNormalizedSize / maxDim) * (slot.customScale ?? 1.0)
            normalScales[slot.index] = finalScale

            let center = SCNVector3((minB.x + maxB.x) / 2, (minB.y + maxB.y) / 2, (minB.z + maxB.z) / 2)
            node.position = SCNVector3(-center.x * finalScale, -center.y * finalScale, -center.z * finalScale)

            // Empieza invisible hasta que la cinemática lo llame.
            node.opacity = 0
            node.scale = SCNVector3(0.01, 0.01, 0.01)
            node.name = slot.name

            holder.addChildNode(node)
            carousel.addChildNode(holder)
            holderNodes[slot.index] = holder
            modelNodes[slot.index] = node

            // Cada modelo gira lentamente sobre su propio eje → da vida aunque el carrusel esté en pausa.
            startSelfOscillation(on: node, duration: slot.selfOscillation)

            // Carga tardía: si la cinemática ya reveló el círculo, este modelo entra de inmediato
            // (evita el "pop-in" secuencial cuando una carga termina después del paso 1).
            if modelsAreVisible {
                revealLateModel(node, slot: slot)
            }
        }

        /// Revela un modelo que terminó de cargar después de `animateModelsIn`, respetando el foco activo.
        private func revealLateModel(_ node: SCNNode, slot: CarouselSlot) {
            let scale = normalScales[slot.index] ?? 1
            let focus = currentHighlight
            let hasFocus = (focus != nil && focus != -99)
            let isFocus = (focus == slot.index)
            let targetScale = isFocus
                ? scale * CarouselConfig.focusScaleMultiplier
                : (hasFocus ? scale * CarouselConfig.dimmedScaleMultiplier : scale)
            let targetOpacity: CGFloat = (hasFocus && !isFocus) ? CarouselConfig.dimmedOpacity : 1.0

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            node.opacity = targetOpacity
            node.scale = SCNVector3(targetScale, targetScale, targetScale)
            SCNTransaction.commit()
        }

        // MARK: Cinematic animations

        func animateModelsIn() {
            // El restaurante (0) queda al frente al formarse el círculo.
            carouselNode?.eulerAngles.y = frontRotation(for: 0)
            for (i, slot) in carouselSlots.enumerated() {
                guard let node = modelNodes[slot.index],
                      let scale = normalScales[slot.index] else { continue }
                let delay = Double(i) * 0.08
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.6
                    SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
                    node.opacity = 1.0
                    node.scale = SCNVector3(scale, scale, scale)
                    SCNTransaction.commit()
                }
            }
        }

        /// Pausa el giro, rota el carrusel para traer `index` al frente y lo destaca; atenúa el resto.
        func focusModel(_ index: Int) {
            carouselNode?.removeAction(forKey: "idleSpin")

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.9
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            carouselNode?.eulerAngles.y = frontRotation(for: index)
            SCNTransaction.commit()

            for slot in carouselSlots {
                guard let node = modelNodes[slot.index],
                      let scale = normalScales[slot.index] else { continue }
                let isFocus = (slot.index == index)
                let targetScale = isFocus
                    ? scale * CarouselConfig.focusScaleMultiplier
                    : scale * CarouselConfig.dimmedScaleMultiplier
                let targetOpacity: CGFloat = isFocus ? 1.0 : CarouselConfig.dimmedOpacity

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.6
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                node.scale = SCNVector3(targetScale, targetScale, targetScale)
                node.opacity = targetOpacity
                SCNTransaction.commit()
            }
        }

        /// Estado final: iguala todos los modelos y reanuda el giro continuo suave.
        func enterRestingState() {
            for slot in carouselSlots {
                guard let node = modelNodes[slot.index],
                      let scale = normalScales[slot.index] else { continue }
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.6
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                node.scale = SCNVector3(scale, scale, scale)
                node.opacity = 1.0
                SCNTransaction.commit()
            }
            // Continúa desde el ángulo actual (-270°) sin saltos.
            carouselNode?.runAction(idleSpinAction(), forKey: "idleSpin")
        }

        // MARK: Hold vibration

        func setHoldVibrating(_ on: Bool) {
            guard on != isCurrentlyVibrating, !exitTriggered else { return }
            isCurrentlyVibrating = on

            if on { carouselNode?.removeAction(forKey: "idleSpin") }

            for slot in carouselSlots {
                guard let node = modelNodes[slot.index] else { continue }
                if on {
                    node.removeAction(forKey: "selfOsc")
                    let shake = SCNAction.repeatForever(.sequence([
                        .rotateBy(x: 0.045, y: 0.03, z: 0.035, duration: 0.05),
                        .rotateBy(x: -0.045, y: -0.03, z: -0.035, duration: 0.05),
                        .rotateBy(x: -0.03, y: 0.022, z: -0.025, duration: 0.05),
                        .rotateBy(x: 0.03, y: -0.022, z: 0.025, duration: 0.05),
                    ]))
                    node.runAction(shake, forKey: "holdShake")
                } else {
                    node.removeAction(forKey: "holdShake")
                    startSelfOscillation(on: node, duration: slot.selfOscillation)
                }
            }

            // Si soltó sin completar y ya estábamos en reposo, reanuda el giro.
            if !on && restingStarted && !exitTriggered {
                carouselNode?.runAction(idleSpinAction(), forKey: "idleSpin")
            }
        }

        // MARK: Exit animation

        /// Duración del viaje del restaurante hacia su pose del Home (sincronizada con el
        /// scaleEffect/offset de SwiftUI en OnboardingView).
        static let exitMoveDelay: Double = 0.26
        static let exitMoveDuration: Double = 1.6   // viaje lento y cinemático hacia la pose del Home

        func runExitAnimation() {
            carouselNode?.removeAction(forKey: "idleSpin")
            for slot in carouselSlots {
                modelNodes[slot.index]?.removeAction(forKey: "selfOsc")
                modelNodes[slot.index]?.removeAction(forKey: "holdShake")
            }

            // Fase 1: vibración breve y suave de todos (0 – 0.24s).
            let vibrate = SCNAction.sequence([
                .rotateBy(x: 0.06, y: 0.04, z: 0.05, duration: 0.04),
                .rotateBy(x: -0.06, y: -0.04, z: -0.05, duration: 0.04),
                .rotateBy(x: -0.05, y: 0.03, z: -0.04, duration: 0.04),
                .rotateBy(x: 0.05, y: -0.03, z: 0.04, duration: 0.04),
                .rotateBy(x: 0.035, y: 0.02, z: 0.025, duration: 0.04),
                .rotateBy(x: -0.035, y: -0.02, z: -0.025, duration: 0.04),
            ])
            for slot in carouselSlots { modelNodes[slot.index]?.runAction(vibrate) }

            // Fase 2: el restaurante viaja a su pose EXACTA del Home; el resto se dispersa.
            // Pose Home (ver HomeView/MultiModel3DCarouselView): modelo centrado en el origen del mundo,
            // escala 2.5/maxDim, sin rotación, cámara cenital (0,4,0)/(-90°)/FOV 55.
            let dur = Self.exitMoveDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.exitMoveDelay) { [weak self] in
                guard let self else { return }

                // homeRatio convierte la escala del onboarding (1.4/maxDim) a la del Home (2.5/maxDim).
                // exitHandoffScale baja el tamaño al del Home en pantalla → el modelo se renderiza
                // ya pequeño (no gigante) y NO se recorta por los lados.
                let homeRatio = Float(2.5 / Double(CarouselConfig.modelNormalizedSize))
                let sizeFactor = homeRatio * self.exitHandoffScale

                SCNTransaction.begin()
                SCNTransaction.animationDuration = dur
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                // Carrusel y holder del restaurante → origen del mundo, sin rotación.
                self.carouselNode?.position = SCNVector3(0, 0, 0)
                self.carouselNode?.eulerAngles = SCNVector3(0, 0, 0)
                self.holderNodes[0]?.position = SCNVector3(0, 0, 0)

                // Restaurante → escala/centro/rotación del Home (tamaño en pantalla ya igualado).
                if let rest = self.modelNodes[0], let s = self.normalScales[0] {
                    let hs = s * sizeFactor
                    let p = rest.position           // = -center * (1.4/maxDim)
                    rest.scale = SCNVector3(hs, hs, hs)
                    rest.position = SCNVector3(p.x * sizeFactor, p.y * sizeFactor, p.z * sizeFactor)
                    rest.eulerAngles = SCNVector3(0, 0, 0)
                    rest.opacity = 1.0
                }

                // Cámara → cenital del Home.
                self.cameraNode?.position = SCNVector3(0, 4.0, 0)
                self.cameraNode?.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                self.cameraNode?.camera?.fieldOfView = 55

                SCNTransaction.commit()

                // El resto simplemente se desvanece en su sitio (fade suave), sin salir volando.
                for slot in carouselSlots where slot.index != 0 {
                    guard let holder = self.holderNodes[slot.index] else { continue }
                    let fade = SCNAction.fadeOut(duration: 0.7)
                    fade.timingMode = .easeInEaseOut
                    holder.runAction(fade)
                }
            }

            // Fase 3: red de seguridad. El relevo al Home lo conduce el withAnimation(completion:) de
            // OnboardingView (revela Home + solapa el restaurante + retira el overlay). Este callback
            // queda BIEN después de ese solapamiento, solo por si aquella completion no se disparara.
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.exitMoveDelay + dur + 0.5) { [weak self] in
                self?.onExitComplete()
            }
        }

        // MARK: Helpers

        private func startSelfOscillation(on node: SCNNode, duration: Double) {
            let osc = SCNAction.repeatForever(.sequence([
                .rotateBy(x: 0, y: CGFloat.pi / 7, z: 0, duration: duration),
                .rotateBy(x: 0, y: -CGFloat.pi / 7, z: 0, duration: duration),
            ]))
            node.runAction(osc, forKey: "selfOsc")
        }
    }
}
