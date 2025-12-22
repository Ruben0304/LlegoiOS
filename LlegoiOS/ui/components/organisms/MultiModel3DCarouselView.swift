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

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = allowsCameraControl
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.clipsToBounds = false
        sceneView.layer.masksToBounds = false
        context.coordinator.currentIndex = currentIndex
        context.coordinator.modelNodes.removeAll()
        disableZoomGestures(on: sceneView)

        // Create scene
        let scene = SCNScene()

        // Configure camera - Posición fija para todos los modelos
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100

        // Posición de cámara fija (no se mueve entre modelos)
        cameraNode.position = cameraPosition(for: currentIndex)
        cameraNode.eulerAngles = cameraEulerAngles(for: currentIndex)

        scene.rootNode.addChildNode(cameraNode)
        context.coordinator.cameraNode = cameraNode

        // Gestos para rotar únicamente el modelo actual (sin zoom)
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)

        // Cargar y posicionar todos los modelos EN EL MISMO LUGAR
        for (index, model) in models.enumerated() {
            if let modelURL = Bundle.main.url(forResource: model.fileName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
                if let modelScene = try? SCNScene(url: modelURL, options: nil) {
                    let modelNode = modelScene.rootNode.clone()

                    // Center and scale the model
                    let (minBounds, maxBounds) = modelNode.boundingBox
                    let size = SCNVector3(
                        x: maxBounds.x - minBounds.x,
                        y: maxBounds.y - minBounds.y,
                        z: maxBounds.z - minBounds.z
                    )
                    let maxDimension = max(size.x, max(size.y, size.z))
                    
                    // Usar escala personalizada si existe, sino usar el cálculo automático
                    let baseScale: Float = 2.5 / maxDimension
                    let finalScale = baseScale * (model.customScale ?? 1.0)
                    
                    modelNode.scale = SCNVector3(x: finalScale, y: finalScale, z: finalScale)

                    // Centrar el modelo
                    let center = SCNVector3(
                        x: (minBounds.x + maxBounds.x) / 2,
                        y: (minBounds.y + maxBounds.y) / 2,
                        z: (minBounds.z + maxBounds.z) / 2
                    )

                    // TODOS los modelos en la MISMA posición (x=0)
                    modelNode.position = SCNVector3(
                        x: -center.x * finalScale,
                        y: -center.y * finalScale,
                        z: -center.z * finalScale
                    )

                    // Configurar opacidad inicial: visible sólo si es el modelo actual
                    modelNode.opacity = (index == currentIndex) ? 1.0 : 0.0

                    // Añadir nombre para identificarlo
                    modelNode.name = "model_\(index)"
                    context.coordinator.modelNodes[index] = modelNode

                    // Animación de rotación suave
                    if isAnimated {
                        let rotateLeft = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 6, z: 0, duration: 25.0)
                        let rotateRight = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 6, z: 0, duration: 25.0)
                        let sequence = SCNAction.sequence([rotateLeft, rotateRight])
                        let repeatOscillation = SCNAction.repeatForever(sequence)
                        modelNode.runAction(repeatOscillation)
                    }

                    scene.rootNode.addChildNode(modelNode)
                }
            }
        }

        sceneView.scene = scene
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let cameraNode = context.coordinator.cameraNode else { return }
        
        let previousIndex = context.coordinator.currentIndex
        context.coordinator.currentIndex = currentIndex

        // Si el índice cambió, animar slide de los modelos
        if previousIndex != currentIndex {
            // Slide out del modelo anterior hacia la izquierda
            if let previousNode = context.coordinator.modelNodes[previousIndex] {
                let currentPosition = previousNode.position
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.7
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                // Mover hacia la izquierda y desvanecer
                previousNode.position = SCNVector3(
                    x: currentPosition.x - 3.0,
                    y: currentPosition.y,
                    z: currentPosition.z
                )
                previousNode.opacity = 0.0
                
                SCNTransaction.commit()
            }
            
            // Slide in del modelo actual desde la izquierda hacia la derecha
            if let currentNode = context.coordinator.modelNodes[currentIndex] {
                // Obtener la posición final (centro)
                let (minBounds, maxBounds) = currentNode.boundingBox
                let scale = currentNode.scale.x
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
                
                // Posicionar inicialmente a la IZQUIERDA (mismo lado) y transparente
                currentNode.position = SCNVector3(
                    x: finalPosition.x - 3.0,  // Cambio: ahora viene desde la izquierda
                    y: finalPosition.y,
                    z: finalPosition.z
                )
                currentNode.opacity = 0.0
                
                // Animar entrada desde la izquierda hacia la derecha
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.7
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                currentNode.position = finalPosition
                currentNode.opacity = 1.0
                
                SCNTransaction.commit()
            }
            
            // Actualizar ángulos de cámara según el modelo
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.7
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraNode.position = cameraPosition(for: currentIndex)
            cameraNode.eulerAngles = cameraEulerAngles(for: currentIndex)
            SCNTransaction.commit()
        }
        
        disableZoomGestures(on: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var cameraNode: SCNNode?
        var modelNodes: [Int: SCNNode] = [:]
        var currentIndex: Int = 0

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            guard let modelNode = modelNodes[currentIndex] else { return }

            let translation = gesture.translation(in: view)
            let rotationY = Float(translation.x) * 0.005
            let rotationX = Float(translation.y) * 0.005

            modelNode.eulerAngles.y -= rotationY

            // Limitar la inclinación en X para evitar volteos extremos
            let proposedX = modelNode.eulerAngles.x - rotationX
            let clampedX = min(max(proposedX, -Float.pi / 4), Float.pi / 4)
            modelNode.eulerAngles.x = clampedX

            // Reiniciar la traducción para usar deltas pequeños
            gesture.setTranslation(.zero, in: view)
        }
    }

    private func cameraPosition(for index: Int) -> SCNVector3 {
        let base = models[index].cameraPosition ?? defaultCameraPosition
        return SCNVector3(
            x: base.x,
            y: base.y,
            z: base.z
        )
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
}
