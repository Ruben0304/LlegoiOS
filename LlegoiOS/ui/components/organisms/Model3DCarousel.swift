import SwiftUI
import SceneKit

struct Model3DCarousel: View {
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var scaleEffect: CGFloat = 1.2

    let models: [CategoryModel3D] = [
        CategoryModel3D(
            name: "Mercadito",
            fileName: "Fruit_Veg_Market.usdz",
            description: "Frutas y Vegetales Frescos",
            icon: "cart.fill",
            cameraPosition: SCNVector3(x: 0, y: 1.5, z: 3.2), // Elevar cámara
            cameraEulerAngles: SCNVector3(x: -.pi / 6, y: 0, z: 0) // Ángulo intermedio: ~30 grados desde arriba
        ),
        CategoryModel3D(
            name: "Tienda de Ropa",
            fileName: "Adidas_display_-_Visual_Merchandising_guideline.usdz",
            description: "Moda y Accesorios",
            icon: "tshirt.fill"
        ),
        CategoryModel3D(
            name: "Agro",
            fileName: "Snack_Shelf.usdz",
            description: "Productos Agrícolas",
            icon: "leaf.fill"
        )
    ]

    var body: some View {
        VStack(spacing: 40) {
            // 3D Model Display Area
            SceneKitView(
                modelName: models[currentIndex].fileName,
                cameraPosition: models[currentIndex].cameraPosition,
                cameraEulerAngles: models[currentIndex].cameraEulerAngles
            )
                .frame(height: 520)
                .frame(maxWidth: .infinity)
                .scaleEffect(scaleEffect)
                .offset(x: dragOffset)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: scaleEffect)

            // Category navigation
            HStack(spacing: 24) {
                ArrowButton(direction: .left) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        if currentIndex > 0 {
                            currentIndex -= 1
                            animateTransition()
                        }
                    }
                }
                .opacity(currentIndex > 0 ? 1 : 0.3)
                .disabled(currentIndex == 0)

                Text(models[currentIndex].name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                ArrowButton(direction: .right) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        if currentIndex < models.count - 1 {
                            currentIndex += 1
                            animateTransition()
                        }
                    }
                }
                .opacity(currentIndex < models.count - 1 ? 1 : 0.3)
                .disabled(currentIndex == models.count - 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func animateTransition() {
        // Scale animation for smooth transition
        scaleEffect = 0.92
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            scaleEffect = 1.0
        }
    }
}

// MARK: - Arrow Button
struct ArrowButton: View {
    enum Direction {
        case left, right

        var iconName: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
    }

    enum Size {
        case regular, small

        var buttonSize: CGFloat {
            switch self {
            case .regular: return 44
            case .small: return 36
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .regular: return 18
            case .small: return 14
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .regular: return 1.5
            case .small: return 1.2
            }
        }
    }

    let direction: Direction
    let size: Size
    let action: () -> Void

    init(direction: Direction, size: Size = .regular, action: @escaping () -> Void) {
        self.direction = direction
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: direction.iconName)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size.buttonSize, height: size.buttonSize)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.5),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: size.strokeWidth
                                )
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ArrowScaleButtonStyle())
    }
}

// MARK: - Arrow Scale Button Style
struct ArrowScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - SceneKit View
struct SceneKitView: UIViewRepresentable {
    let modelName: String
    var allowsCameraControl: Bool = true
    var isAnimated: Bool = true
    var cameraPosition: SCNVector3?
    var cameraEulerAngles: SCNVector3?
    var sceneCustomizer: ((SCNScene) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.allowsCameraControl = allowsCameraControl
        sceneView.autoenablesDefaultLighting = true
        sceneView.antialiasingMode = .multisampling4X
        sceneView.clipsToBounds = false
        sceneView.layer.masksToBounds = false

        // Configure camera - centered for proper view
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50  // Reduced FOV for more zoom

        // Lock zoom by setting fixed distance constraints
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100

        configureCamera(cameraNode)

        // Create scene
        let scene = SCNScene()
        scene.rootNode.addChildNode(cameraNode)

        // Load 3D model
        if let modelURL = Bundle.main.url(forResource: modelName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
            if let modelScene = try? SCNScene(url: modelURL, options: nil) {
                let modelNode = modelScene.rootNode

                // Center and scale the model
                let (minBounds, maxBounds) = modelNode.boundingBox
                let size = SCNVector3(
                    x: maxBounds.x - minBounds.x,
                    y: maxBounds.y - minBounds.y,
                    z: maxBounds.z - minBounds.z
                )
                let maxDimension = max(size.x, max(size.y, size.z))
                let scale = 1.9 / maxDimension  // Reduced zoom (from 2.1 to 1.9)
                modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)

                // Center the model properly (vertically centered)
                let center = SCNVector3(
                    x: (minBounds.x + maxBounds.x) / 2,
                    y: (minBounds.y + maxBounds.y) / 2,
                    z: (minBounds.z + maxBounds.z) / 2
                )
                // Center the model at origin (no Y offset to keep it centered)
                modelNode.position = SCNVector3(x: -center.x * scale, y: -center.y * scale, z: -center.z * scale)

                scene.rootNode.addChildNode(modelNode)

                if isAnimated {
                    let rotateLeft = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 6, z: 0, duration: 25.0)
                    let rotateRight = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 6, z: 0, duration: 25.0)
                    let sequence = SCNAction.sequence([rotateLeft, rotateRight])
                    let repeatOscillation = SCNAction.repeatForever(sequence)
                    modelNode.runAction(repeatOscillation)
                }
            }
        }

        sceneCustomizer?(scene)
        sceneView.scene = scene
        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the model when modelName changes
        guard let scene = uiView.scene else { return }

        uiView.allowsCameraControl = allowsCameraControl

        if let cameraNode = scene.rootNode.childNodes.first(where: { $0.camera != nil }) {
            configureCamera(cameraNode)
        }

        // Remove previous model
        scene.rootNode.childNodes.forEach { node in
            if node.camera == nil {
                node.removeFromParentNode()
            }
        }

        // Load new model
        if let modelURL = Bundle.main.url(forResource: modelName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
            if let modelScene = try? SCNScene(url: modelURL, options: nil) {
                let modelNode = modelScene.rootNode

                // Center and scale the model
                let (minBounds, maxBounds) = modelNode.boundingBox
                let size = SCNVector3(
                    x: maxBounds.x - minBounds.x,
                    y: maxBounds.y - minBounds.y,
                    z: maxBounds.z - minBounds.z
                )
                let maxDimension = max(size.x, max(size.y, size.z))
                let scale = 1.9 / maxDimension  // Reduced zoom (from 2.1 to 1.9)
                modelNode.scale = SCNVector3(x: scale, y: scale, z: scale)

                // Center the model properly (vertically centered)
                let center = SCNVector3(
                    x: (minBounds.x + maxBounds.x) / 2,
                    y: (minBounds.y + maxBounds.y) / 2,
                    z: (minBounds.z + maxBounds.z) / 2
                )
                // Center the model at origin (no Y offset to keep it centered)
                modelNode.position = SCNVector3(x: -center.x * scale, y: -center.y * scale, z: -center.z * scale)

                scene.rootNode.addChildNode(modelNode)

                if isAnimated {
                    let rotateLeft = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 6, z: 0, duration: 25.0)
                    let rotateRight = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 6, z: 0, duration: 25.0)
                    let sequence = SCNAction.sequence([rotateLeft, rotateRight])
                    let repeatOscillation = SCNAction.repeatForever(sequence)
                    modelNode.runAction(repeatOscillation)
                }
            }
        }

        sceneCustomizer?(scene)
    }

    private func configureCamera(_ cameraNode: SCNNode) {
        let defaultPosition = SCNVector3(x: 0, y: 0, z: 3.2)
        cameraNode.position = cameraPosition ?? defaultPosition

        if let cameraEulerAngles = cameraEulerAngles {
            cameraNode.eulerAngles = cameraEulerAngles
        } else {
            cameraNode.eulerAngles = SCNVector3Zero
        }

        // Add distance constraint to lock zoom
        let distance = sqrt(
            pow(cameraNode.position.x, 2) +
            pow(cameraNode.position.y, 2) +
            pow(cameraNode.position.z, 2)
        )
        let distanceConstraint = SCNDistanceConstraint(target: nil)
        distanceConstraint.minimumDistance = CGFloat(distance)
        distanceConstraint.maximumDistance = CGFloat(distance)
        cameraNode.constraints = [distanceConstraint]
    }
}

// MARK: - Model Data
struct CategoryModel3D: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let description: String
    let icon: String
    let cameraPosition: SCNVector3?
    let cameraEulerAngles: SCNVector3?
    let customScale: Float?

    init(
        name: String,
        fileName: String,
        description: String,
        icon: String,
        cameraPosition: SCNVector3? = nil,
        cameraEulerAngles: SCNVector3? = nil,
        customScale: Float? = nil
    ) {
        self.name = name
        self.fileName = fileName
        self.description = description
        self.icon = icon
        self.cameraPosition = cameraPosition
        self.cameraEulerAngles = cameraEulerAngles
        self.customScale = customScale
    }
}
