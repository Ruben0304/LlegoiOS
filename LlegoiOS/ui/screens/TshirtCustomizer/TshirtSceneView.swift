import SwiftUI
import SceneKit
import UIKit

struct TshirtSceneView: UIViewRepresentable {
    let texture: UIImage
    let garmentType: GarmentType
    let gender: GarmentGender
    let shapeVersion: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.defaultCameraController.inertiaEnabled = true
        view.autoenablesDefaultLighting = false
        view.preferredFramesPerSecond = 60
        view.isJitteringEnabled = true

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // Camera ─────────────────────────────────────────────────────────
        let camNode = SCNNode()
        let cam = SCNCamera()
        cam.fieldOfView = 38
        cam.zNear = 0.1
        cam.zFar = 100
        cam.wantsHDR = true
        cam.bloomIntensity = 0.18
        cam.bloomThreshold = 0.85
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, 7.6)
        scene.rootNode.addChildNode(camNode)

        // Lights ─────────────────────────────────────────────────────────
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 950
        key.light?.color = UIColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1)
        key.light?.castsShadow = false
        key.eulerAngles = SCNVector3(-0.55, -0.50, 0)
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 420
        rim.light?.color = UIColor(red: 0.78, green: 0.82, blue: 1.0, alpha: 1)
        rim.eulerAngles = SCNVector3(0.30, 2.4, 0)
        scene.rootNode.addChildNode(rim)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 240
        fill.eulerAngles = SCNVector3(0.65, 0.4, 0)
        scene.rootNode.addChildNode(fill)

        let amb = SCNNode()
        amb.light = SCNLight()
        amb.light?.type = .ambient
        amb.light?.intensity = 280
        amb.light?.color = UIColor(white: 1, alpha: 1)
        scene.rootNode.addChildNode(amb)

        view.scene = scene

        // Shirt ──────────────────────────────────────────────────────────
        rebuildShirtNode(in: scene, context: context)

        // Idle gentle rotation while user isn't interacting
        let pivot = SCNNode()
        pivot.name = "shirtPivot"
        scene.rootNode.addChildNode(pivot)

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let scene = uiView.scene else { return }

        let needsRebuild =
            context.coordinator.lastShapeVersion != shapeVersion ||
            context.coordinator.lastGarmentType  != garmentType  ||
            context.coordinator.lastGender       != gender       ||
            context.coordinator.shirtNode == nil

        if needsRebuild {
            rebuildShirtNode(in: scene, context: context)
        } else if let mat = context.coordinator.shirtNode?.geometry?.firstMaterial {
            mat.diffuse.contents = texture
        }
    }

    private func rebuildShirtNode(in scene: SCNScene, context: Context) {
        context.coordinator.shirtNode?.removeFromParentNode()

        let node = ShirtMeshBuilder.makeShirtNode(
            type: garmentType,
            gender: gender,
            texture: texture
        )

        // Normalize size so different silhouettes occupy the same on-screen area.
        let (minV, maxV) = node.boundingBox
        let h = maxV.y - minV.y
        let w = maxV.x - minV.x
        let target: Float = 4.4
        let factor: Float = target / max(h, w * 1.05)
        node.scale = SCNVector3(factor, factor, factor)

        scene.rootNode.addChildNode(node)
        context.coordinator.shirtNode = node
        context.coordinator.lastShapeVersion = shapeVersion
        context.coordinator.lastGarmentType = garmentType
        context.coordinator.lastGender = gender
    }

    final class Coordinator {
        var shirtNode: SCNNode?
        var lastShapeVersion: Int = -1
        var lastGarmentType: GarmentType = .tshirt
        var lastGender: GarmentGender = .men
    }
}
