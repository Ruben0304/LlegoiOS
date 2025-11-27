import SwiftUI
import SceneKit

struct MultiModel3DCarouselView: UIViewRepresentable {
    let models: [CategoryModel3D]
    let currentIndex: Int
    var allowsCameraControl: Bool = false
    var isAnimated: Bool = true

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = allowsCameraControl
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.clipsToBounds = false
        sceneView.layer.masksToBounds = false

        // Create scene
        let scene = SCNScene()

        // Configure camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100

        // Posición inicial de la cámara (más cerca para modelos más grandes)
        cameraNode.position = SCNVector3(x: 0, y: 1.2, z: 3.5)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 8, y: 0, z: 0)

        scene.rootNode.addChildNode(cameraNode)
        context.coordinator.cameraNode = cameraNode

        // Cargar y posicionar todos los modelos horizontalmente
        let modelSpacing: Float = 6.0 // Separación entre modelos

        for (index, model) in models.enumerated() {
            if let modelURL = Bundle.main.url(forResource: model.fileName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
                if let modelScene = try? SCNScene(url: modelURL, options: nil) {
                    let modelNode = modelScene.rootNode.clone()

                    // Center and scale the model (más grande)
                    let (minBounds, maxBounds) = modelNode.boundingBox
                    let size = SCNVector3(
                        x: maxBounds.x - minBounds.x,
                        y: maxBounds.y - minBounds.y,
                        z: maxBounds.z - minBounds.z
                    )
                    let maxDimension = max(size.x, max(size.y, size.z))
                    let scale = 2.2 / maxDimension  // Aumentado de 1.8 a 2.2
                    modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)

                    // Centrar el modelo verticalmente
                    let center = SCNVector3(
                        x: (minBounds.x + maxBounds.x) / 2,
                        y: (minBounds.y + maxBounds.y) / 2,
                        z: (minBounds.z + maxBounds.z) / 2
                    )

                    // Posicionar el modelo horizontalmente
                    let xPosition = Float(index) * modelSpacing
                    modelNode.position = SCNVector3(
                        x: xPosition - center.x * scale,
                        y: -center.y * scale,
                        z: -center.z * scale
                    )

                    // Añadir nombre para identificarlo
                    modelNode.name = "model_\(index)"

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
        // Animar la cámara a la posición del modelo actual
        guard let cameraNode = context.coordinator.cameraNode else { return }

        let modelSpacing: Float = 6.0
        let targetX = Float(currentIndex) * modelSpacing

        // Animación suave de la cámara
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        cameraNode.position = SCNVector3(x: targetX, y: 1.2, z: 3.5)

        SCNTransaction.commit()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var cameraNode: SCNNode?
    }
}
