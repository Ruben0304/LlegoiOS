import SwiftUI
import SceneKit
import UIKit

struct MultiModel3DCarouselView: UIViewRepresentable {
    let models: [CategoryModel3D]
    let currentIndex: Int
    var allowsCameraControl: Bool = false
    var isAnimated: Bool = true

    private let defaultCameraPosition = SCNVector3(x: 0, y: 1.2, z: 3.5)
    private let defaultCameraEulerAngles = SCNVector3(x: -Float.pi / 8, y: 0, z: 0)

    // Escenas cacheadas; solo se escriben en el main actor
    static var sceneCache: [String: SCNScene] = [:]

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = allowsCameraControl
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling2X  // 4X→2X: -50% GPU
        sceneView.preferredFramesPerSecond = 0         // usa la tasa nativa del display (120Hz en Pro)
        sceneView.clipsToBounds = false
        sceneView.layer.masksToBounds = false
        disableZoomGestures(on: sceneView)

        let scene = SCNScene()

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = cameraPosition(for: currentIndex)
        cameraNode.eulerAngles = cameraEulerAngles(for: currentIndex)
        scene.rootNode.addChildNode(cameraNode)

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)

        let coordinator = context.coordinator
        coordinator.scene = scene
        coordinator.cameraNode = cameraNode
        coordinator.models = models
        coordinator.isAnimated = isAnimated
        coordinator.currentIndex = currentIndex
        coordinator.modelNodes.removeAll()

        sceneView.scene = scene

        // Modelo visible: carga inmediata (caché = instantáneo en navegaciones de vuelta)
        coordinator.loadAndAddModel(at: currentIndex, isVisible: true)

        // Resto: carga en background sin bloquear la UI
        for index in models.indices where index != currentIndex {
            coordinator.loadAndAddModel(at: index, isVisible: false)
        }

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let cameraNode = context.coordinator.cameraNode else { return }

        let coordinator = context.coordinator
        let previousIndex = coordinator.currentIndex
        coordinator.currentIndex = currentIndex
        coordinator.isAnimated = isAnimated

        guard previousIndex != currentIndex else {
            disableZoomGestures(on: uiView)
            return
        }

        // Detener animación y ocultar modelo anterior
        if let previousNode = coordinator.modelNodes[previousIndex] {
            let pos = previousNode.position
            previousNode.removeAction(forKey: "oscillation")

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            previousNode.position = SCNVector3(x: pos.x - 3.0, y: pos.y, z: pos.z)
            previousNode.opacity = 0.0
            SCNTransaction.commit()
        }

        // Animar entrada si el nodo ya está cargado; si no, loadAndAddModel lo mostrará al terminar
        if let currentNode = coordinator.modelNodes[currentIndex] {
            coordinator.animateIn(node: currentNode)
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.7
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.position = cameraPosition(for: currentIndex)
        cameraNode.eulerAngles = cameraEulerAngles(for: currentIndex)
        SCNTransaction.commit()

        disableZoomGestures(on: uiView)
    }

    private func cameraPosition(for index: Int) -> SCNVector3 {
        let base = models[index].cameraPosition ?? defaultCameraPosition
        return SCNVector3(x: base.x, y: base.y, z: base.z)
    }

    private func cameraEulerAngles(for index: Int) -> SCNVector3 {
        models[index].cameraEulerAngles ?? defaultCameraEulerAngles
    }

    private func disableZoomGestures(on sceneView: SCNView) {
        sceneView.gestureRecognizers?.forEach { gesture in
            if gesture is UIPinchGestureRecognizer {
                gesture.isEnabled = false
            }
        }
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject {
        var cameraNode: SCNNode?
        var modelNodes: [Int: SCNNode] = [:]
        var currentIndex: Int = 0
        weak var scene: SCNScene?
        var models: [CategoryModel3D] = []
        var isAnimated: Bool = true

        // Wrapper para enviar SCNScene (no Sendable) a través de continuation
        private struct SceneBox: @unchecked Sendable { let scene: SCNScene? }

        func loadAndAddModel(at index: Int, isVisible: Bool) {
            let model = models[index]
            let key = model.fileName.replacingOccurrences(of: ".usdz", with: "")

            if let cached = MultiModel3DCarouselView.sceneCache[key] {
                addNode(from: cached, at: index, model: model, requestedVisible: isVisible)
                return
            }

            guard let url = Bundle.main.url(forResource: key, withExtension: "usdz") else { return }

            Task { [weak self] in
                // Carga en hilo de fondo, resultado de vuelta al main actor
                let box = await withCheckedContinuation { (continuation: CheckedContinuation<SceneBox, Never>) in
                    DispatchQueue.global(qos: .utility).async {
                        continuation.resume(returning: SceneBox(scene: try? SCNScene(url: url, options: nil)))
                    }
                }
                guard let loaded = box.scene, let self else { return }
                MultiModel3DCarouselView.sceneCache[key] = loaded
                self.addNode(from: loaded, at: index, model: model, requestedVisible: isVisible)
            }
        }

        private func addNode(from modelScene: SCNScene, at index: Int, model: CategoryModel3D, requestedVisible: Bool) {
            guard let scene = scene, modelNodes[index] == nil else { return }

            let modelNode = modelScene.rootNode.clone()

            let (minBounds, maxBounds) = modelNode.boundingBox
            let size = SCNVector3(
                x: maxBounds.x - minBounds.x,
                y: maxBounds.y - minBounds.y,
                z: maxBounds.z - minBounds.z
            )
            let maxDimension = max(size.x, max(size.y, size.z))
            let baseScale: Float = 2.5 / maxDimension
            let finalScale = baseScale * (model.customScale ?? 1.0)
            modelNode.scale = SCNVector3(x: finalScale, y: finalScale, z: finalScale)

            let center = SCNVector3(
                x: (minBounds.x + maxBounds.x) / 2,
                y: (minBounds.y + maxBounds.y) / 2,
                z: (minBounds.z + maxBounds.z) / 2
            )
            modelNode.position = SCNVector3(
                x: -center.x * finalScale,
                y: -center.y * finalScale,
                z: -center.z * finalScale
            )

            if let initialRotation = model.initialRotationY {
                modelNode.eulerAngles.y = initialRotation
            }

            // Si el modelo llegó tarde y el usuario ya navegó a este índice, mostrarlo
            let shouldBeVisible = requestedVisible || (index == currentIndex)
            modelNode.opacity = shouldBeVisible ? 1.0 : 0.0
            modelNode.name = "model_\(index)"
            modelNodes[index] = modelNode

            if isAnimated && shouldBeVisible {
                startOscillation(on: modelNode)
            }

            scene.rootNode.addChildNode(modelNode)
        }

        func animateIn(node: SCNNode) {
            let (minBounds, maxBounds) = node.boundingBox
            let scale = node.scale.x
            let center = SCNVector3(
                x: (minBounds.x + maxBounds.x) / 2,
                y: (minBounds.y + maxBounds.y) / 2,
                z: (minBounds.z + maxBounds.z) / 2
            )
            let finalPosition = SCNVector3(
                x: -center.x * scale,
                y: -center.y * scale,
                z: -center.z * scale
            )

            node.position = SCNVector3(x: finalPosition.x - 3.0, y: finalPosition.y, z: finalPosition.z)
            node.opacity = 0.0

            if isAnimated {
                startOscillation(on: node)
            }

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            node.position = finalPosition
            node.opacity = 1.0
            SCNTransaction.commit()
        }

        func startOscillation(on node: SCNNode) {
            let rotateLeft = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 6, z: 0, duration: 25.0)
            let rotateRight = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 6, z: 0, duration: 25.0)
            node.runAction(SCNAction.repeatForever(.sequence([rotateLeft, rotateRight])), forKey: "oscillation")
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            guard let modelNode = modelNodes[currentIndex] else { return }

            let translation = gesture.translation(in: view)
            modelNode.eulerAngles.y -= Float(translation.x) * 0.005

            let proposedX = modelNode.eulerAngles.x - Float(translation.y) * 0.005
            modelNode.eulerAngles.x = min(max(proposedX, -Float.pi / 4), Float.pi / 4)

            gesture.setTranslation(.zero, in: view)
        }
    }
}
