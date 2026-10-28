import SwiftUI
import SceneKit

enum FirstCartStage: Int, Sendable {
    case appearing, loading, driving, confirmation

    var duration: TimeInterval {
        switch self {
        case .appearing: 0.30
        case .loading: 0.80
        case .driving: 1.05
        case .confirmation: 0
        }
    }
}

struct FirstCartCelebration: View {
    let photo: CartFlightPhoto
    let accent: Color
    let onFinish: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var stage = FirstCartStage.appearing
    @State private var image: UIImage?
    @State private var revealed = false
    @State private var isFinishing = false
    @State private var dismissalDuration: TimeInterval = 0.22

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                CelebrationBackdrop()
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    FirstCartScene(
                        image: image, accent: accent, stage: stage, reduceMotion: reduceMotion,
                        viewportSize: CGSize(width: geometry.size.width, height: min(geometry.size.height * 0.43, 350)))
                        .frame(height: min(geometry.size.height * 0.43, 350))
                        .accessibilityHidden(true)

                    Label("Añadido al carrito", systemImage: "checkmark.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(colorScheme == .dark ? Color.llegoAccent : Color.llegoPrimary)
                        .opacity(stage == .driving || stage == .confirmation ? 1 : 0)
                        .accessibilityHidden(stage != .confirmation)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if stage != .confirmation {
                    Button("Omitir") { finish() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(16)
                        .contentShape(Rectangle())
                        .padding(.top, max(geometry.safeAreaInsets.top, 44) - 4)
                        .padding(.trailing, 12)
                }
            }
        }
        .opacity(revealed ? 1 : 0)
        .allowsHitTesting(!isFinishing)
        .accessibilityAddTraits(.isModal)
        .task(id: stage) {
            guard stage == .confirmation else { return }
            do {
                try await Task.sleep(for: .milliseconds(voiceOverEnabled ? 4200 : 1800))
                try Task.checkCancellation()
                finish()
            } catch { }
        }
        .task(id: isFinishing) {
            guard isFinishing else { return }
            do {
                try await Task.sleep(for: .seconds(dismissalDuration))
                try Task.checkCancellation()
                onFinish()
            } catch { }
        }
        .task(id: reduceMotion) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.20)) { revealed = true }
            if reduceMotion || voiceOverEnabled {
                stage = .confirmation
                return
            }
            stage = .appearing
            do {
                try await Task.sleep(for: .seconds(FirstCartStage.appearing.duration))
                guard !isFinishing else { return }
                stage = .loading
                try await Task.sleep(for: .seconds(FirstCartStage.loading.duration))
                try Task.checkCancellation()
                guard !isFinishing else { return }
                stage = .driving
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                // Keep SceneKit running during the fade; dismiss only after the cart exits.
                finish(duration: FirstCartStage.driving.duration)
            } catch { /* Dismissal cancels the sequence. */ }
        }
        .task(id: photo.url) {
            image = photo.cachedImage
            guard image == nil, let url = photo.url else { return }
            if let (data, response) = try? await URLSession.shared.data(from: url),
               let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
               !Task.isCancelled {
                image = UIImage(data: data)
            }
        }
    }

    private func finish(duration: TimeInterval? = nil) {
        guard !isFinishing else { return }
        dismissalDuration = duration ?? (reduceMotion ? 0 : 0.22)
        isFinishing = true
        withAnimation(.easeIn(duration: dismissalDuration)) { revealed = false }
    }
}

private struct FirstCartScene: UIViewRepresentable {
    let image: UIImage?
    let accent: Color
    let stage: FirstCartStage
    let reduceMotion: Bool
    let viewportSize: CGSize

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60
        view.isUserInteractionEnabled = false
        context.coordinator.configure(view, accent: UIColor(accent))
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.updateViewport(viewportSize)
        context.coordinator.updatePhoto(image)
        context.coordinator.setStage(stage, reduceMotion: reduceMotion)
        view.isPlaying = !reduceMotion && stage != .confirmation
    }

    static func dismantleUIView(_ view: SCNView, coordinator: Coordinator) {
        coordinator.cart.removeAllActions()
        coordinator.product.removeAllActions()
        coordinator.photoTile.removeAllActions()
        coordinator.cartShadow.removeAllActions()
        coordinator.product.removeAllParticleSystems()
        view.isPlaying = false
        view.scene = nil
    }

    @MainActor
    final class Coordinator {
        let cart = SCNNode()
        let product = SCNNode()
        let photoTile = SCNNode()
        let cartShadow = SCNNode()
        private let photoMaterial = SCNMaterial()
        private var currentStage: FirstCartStage?
        private var currentReduceMotion: Bool?
        private var currentImage: UIImage?
        private var exitPositionX: Float = 4.65
        private let sideAngle: Float = 1.05
        private let productRestPosition = SCNVector3(0, 1.47, 0)

        func configure(_ view: SCNView, accent: UIColor) {
            let scene = SCNScene()
            scene.background.contents = UIColor.clear
            let camera = SCNNode()
            camera.camera = SCNCamera()
            camera.camera?.usesOrthographicProjection = true
            camera.camera?.orthographicScale = 1.95
            camera.camera?.wantsHDR = false
            camera.position = SCNVector3(0, 3.1, 7)
            camera.look(at: SCNVector3(0, 1.05, 0))
            scene.rootNode.addChildNode(camera)
            view.pointOfView = camera

            addSoftLight(to: scene, at: SCNVector3(-3, 5, 5), intensity: 950, temperature: 6500)
            addSoftLight(to: scene, at: SCNVector3(4, 3, 1), intensity: 480, temperature: 7200)
            addSoftLight(to: scene, at: SCNVector3(0, 4, -3), intensity: 650, temperature: 5500)
            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.color = UIColor.white
            ambient.light?.intensity = 360
            scene.rootNode.addChildNode(ambient)
            scene.rootNode.addChildNode(cart)
            cart.eulerAngles.y = sideAngle
            buildCart()
            addContactShadow(to: scene)

            let plane = SCNPlane(width: 0.72, height: 0.72)
            photoMaterial.lightingModel = .constant
            photoMaterial.isDoubleSided = true
            photoMaterial.diffuse.contents = circularPhoto(nil)
            photoMaterial.writesToDepthBuffer = false
            plane.materials = [photoMaterial]
            photoTile.geometry = plane
            product.addChildNode(photoTile)
            let billboard = SCNBillboardConstraint()
            billboard.freeAxes = .all
            product.constraints = [billboard]
            product.position = SCNVector3(0, 6, 0)
            product.opacity = 0
            cart.addChildNode(product)
            view.scene = scene
        }

        func updatePhoto(_ image: UIImage?) {
            guard let image, image !== currentImage else { return }
            currentImage = image
            photoMaterial.diffuse.contents = circularPhoto(image)
        }

        func updateViewport(_ size: CGSize) {
            guard size.width > 0, size.height > 0 else { return }
            // Include the cart's rear and shadow beyond the viewport, even in landscape.
            exitPositionX = Float(1.95 * max(1, size.width / size.height) + 2.7)
        }

        func setStage(_ stage: FirstCartStage, reduceMotion: Bool) {
            guard stage != currentStage || reduceMotion != currentReduceMotion else { return }
            currentStage = stage
            currentReduceMotion = reduceMotion
            cart.removeAllActions()
            product.removeAllActions()
            photoTile.removeAllActions()
            cartShadow.removeAllActions()

            if reduceMotion || stage == .confirmation {
                resetCart()
                product.opacity = 1
                product.position = productRestPosition
                return
            }

            switch stage {
            case .appearing:
                resetCart()
                product.opacity = 0
                product.position = SCNVector3(0, 4.4, 0)
            case .loading:
                resetCart()
                product.opacity = 1
                product.position = SCNVector3(0, 4.4, 0)
                let fall = SCNAction.move(to: productRestPosition, duration: 0.56)
                fall.timingMode = .easeIn
                let settleUp = SCNAction.move(to: SCNVector3(0, 1.57, 0), duration: 0.10)
                settleUp.timingMode = .easeOut
                let settleDown = SCNAction.move(to: productRestPosition, duration: 0.14)
                settleDown.timingMode = .easeInEaseOut
                product.runAction(.sequence([fall, settleUp, settleDown]), forKey: "product.drop")
            case .driving:
                resetCart()
                product.opacity = 1
                product.position = productRestPosition
                // The model faces right. Move along screen X without turning or deforming it.
                let drive = SCNAction.move(to: SCNVector3(exitPositionX, 0, 0), duration: stage.duration)
                drive.timingMode = .easeIn
                cart.runAction(drive, forKey: "cart.exit")
                let shadowDrive = SCNAction.move(to: SCNVector3(exitPositionX, 0.005, 0), duration: stage.duration)
                shadowDrive.timingMode = .easeIn
                cartShadow.runAction(shadowDrive, forKey: "shadow.exit")
            case .confirmation:
                break
            }
        }

        private func resetCart() {
            cart.opacity = 1
            cart.position = SCNVector3Zero
            cart.eulerAngles = SCNVector3(0, sideAngle, 0)
            product.scale = SCNVector3(1, 1, 1)
            photoTile.eulerAngles = SCNVector3Zero
            cartShadow.position = SCNVector3(0, 0.005, 0)
            cartShadow.scale = SCNVector3(1, 1, 1)
            cartShadow.opacity = 1
        }

        private func buildCart() {
            guard let url = Bundle.main.url(forResource: "shopping_cart", withExtension: "usdz"),
                  let imported = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
                assertionFailure("Missing or invalid shopping_cart.usdz")
                return
            }

            let (minimum, maximum) = imported.rootNode.boundingBox
            let height = maximum.y - minimum.y
            guard height.isFinite, height > 0 else {
                assertionFailure("Invalid shopping cart model bounds")
                return
            }

            // Normalize the supplied asset's units and origin without altering its geometry.
            let model = SCNNode()
            for child in imported.rootNode.childNodes {
                child.removeFromParentNode()
                model.addChildNode(child)
            }
            let scale = Float(2.05) / height
            model.scale = SCNVector3(scale, scale, scale)
            model.position = SCNVector3(
                -(minimum.x + maximum.x) * 0.5 * scale,
                -minimum.y * scale,
                -(minimum.z + maximum.z) * 0.5 * scale)

            // Keep the supplied mesh, with satin finishes from Llego's palette.
            model.enumerateChildNodes { node, _ in
                node.camera = nil
                node.light = nil
                for material in node.geometry?.materials ?? [] {
                    material.lightingModel = .blinn
                    material.specular.contents = UIColor(white: 0.4, alpha: 1)
                    material.shininess = 0.32
                    material.metalness.contents = 0
                    material.roughness.contents = 0.68
                    switch material.name?.lowercased() {
                    case "griff":
                        material.diffuse.contents = UIColor(Color.llegoAccent)
                        material.specular.contents = UIColor(white: 0.2, alpha: 1)
                    case "chrome":
                        material.diffuse.contents = UIColor(red: 0.075, green: 0.28, blue: 0.27, alpha: 1)
                    default:
                        material.diffuse.contents = UIColor(red: 0.10, green: 0.15, blue: 0.15, alpha: 1)
                        material.specular.contents = UIColor.black
                    }
                }
            }
            cart.addChildNode(model)
        }

        private func addSoftLight(to scene: SCNScene, at position: SCNVector3, intensity: CGFloat, temperature: CGFloat) {
            let light = SCNNode()
            light.light = SCNLight()
            light.light?.type = .omni
            light.light?.intensity = intensity
            light.light?.temperature = temperature
            light.position = position
            scene.rootNode.addChildNode(light)
        }

        private func addContactShadow(to scene: SCNScene) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let texture = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
                let colors = [UIColor.black.withAlphaComponent(0.22).cgColor, UIColor.clear.cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
                context.cgContext.drawRadialGradient(
                    gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 0,
                    endCenter: CGPoint(x: 128, y: 128), endRadius: 124, options: [])
            }
            let plane = SCNPlane(width: 2.7, height: 1.8)
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.diffuse.contents = texture
            material.writesToDepthBuffer = false
            plane.materials = [material]
            cartShadow.geometry = plane
            cartShadow.eulerAngles.x = -.pi / 2
            cartShadow.position = SCNVector3(0, 0.005, 0)
            scene.rootNode.addChildNode(cartShadow)
        }

        private func circularPhoto(_ image: UIImage?) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.preferredRange = .standard
            return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
                let bounds = CGRect(x: 4, y: 4, width: 248, height: 248)
                context.cgContext.saveGState()
                UIBezierPath(ovalIn: bounds).addClip()
                UIColor.white.setFill()
                context.fill(bounds)
                if let image {
                    let scale = max(bounds.width / image.size.width, bounds.height / image.size.height)
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    image.draw(in: CGRect(x: 128 - size.width / 2, y: 128 - size.height / 2, width: size.width, height: size.height))
                } else {
                    UIImage(systemName: "photo")?.withTintColor(.gray).draw(in: CGRect(x: 88, y: 88, width: 80, height: 80))
                }
                context.cgContext.restoreGState()
                UIColor(Color.llegoAccent).setStroke()
                let ring = UIBezierPath(ovalIn: bounds)
                ring.lineWidth = 6
                ring.stroke()
            }
        }
    }
}

private struct CelebrationBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.adaptiveBackground(colorScheme)
                    .opacity(reduceTransparency ? 1 : 0.92)
                Ellipse()
                    .fill(Color.llegoAccent.opacity(colorScheme == .dark ? 0.09 : 0.20))
                    .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.3)
                    .blur(radius: 65)
                    .offset(x: -15, y: -60)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

