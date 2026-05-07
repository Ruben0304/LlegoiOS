import UIKit
import SceneKit

/// Generates a procedural shirt mesh from a 2D silhouette path.
/// Produces an SCNNode shaped like the selected garment / gender combo,
/// with the front face textured by the live composite UIImage.
enum ShirtMeshBuilder {

    static func makeShirtNode(type: GarmentType,
                              gender: GarmentGender,
                              texture: UIImage) -> SCNNode {
        let path = silhouettePath(type: type, gender: gender)
        path.flatness = 0.005

        let depth: CGFloat = (type == .pullover) ? 0.22 : 0.16
        let shape = SCNShape(path: path, extrusionDepth: depth)
        shape.chamferRadius = 0.05

        // Front (with composited design)
        let front = SCNMaterial()
        front.diffuse.contents = texture
        front.diffuse.wrapS = .clamp
        front.diffuse.wrapT = .clamp
        front.roughness.contents = 0.85
        front.metalness.contents = 0.0
        front.lightingModel = .physicallyBased
        front.isDoubleSided = false

        // Back (solid base color sampled from the texture)
        let back = SCNMaterial()
        back.diffuse.contents = averageBaseColor(of: texture)
        back.roughness.contents = 0.9
        back.lightingModel = .physicallyBased

        // Side / chamfer
        let side = SCNMaterial()
        side.diffuse.contents = darken(averageBaseColor(of: texture), by: 0.10)
        side.roughness.contents = 0.95
        side.lightingModel = .physicallyBased

        // SCNShape material slot order:
        //   0: front face
        //   1: back face
        //   2: extruded sides (single material wraps the whole rim)
        shape.materials = [front, back, side]

        let node = SCNNode(geometry: shape)

        // Center pivot on bbox so rotation feels natural.
        let (minV, maxV) = node.boundingBox
        let cx = (minV.x + maxV.x) * 0.5
        let cy = (minV.y + maxV.y) * 0.5
        let cz = (minV.z + maxV.z) * 0.5
        node.pivot = SCNMatrix4MakeTranslation(cx, cy, cz)
        node.position = SCNVector3(0, 0, 0)

        // Slight tilt for a nicer "hanging" presentation.
        node.eulerAngles.x = 0
        node.eulerAngles.y = 0
        node.name = "shirt"

        return node
    }

    // MARK: - Silhouette Path

    private static func silhouettePath(type: GarmentType,
                                       gender: GarmentGender) -> UIBezierPath {
        let isWomen   = (gender == .women)
        let isPullovr = (type == .pullover)

        // ─── Vertical landmarks ──────────────────────────────────────────
        let shoulderY:        CGFloat = 1.60
        let collarDipY:       CGFloat = isWomen ? 1.36 : 1.40
        let armpitY:          CGFloat = 1.05
        let chestY:           CGFloat = 0.40
        let waistY:           CGFloat = isWomen ? -0.30 : -0.40
        let hemY:             CGFloat = isPullovr ? -1.65 : -1.50

        // ─── Horizontal landmarks ────────────────────────────────────────
        let collarHalfW:      CGFloat = isWomen ? 0.30 : 0.34
        let collarTopHalfW:   CGFloat = isWomen ? 0.34 : 0.38
        let shoulderHalfW:    CGFloat = isWomen ? 1.20 : 1.30
        let sleeveOuterX:     CGFloat = isPullovr ? 2.05 : 1.85
        let sleeveCuffTopY:   CGFloat = isPullovr ? 0.65 : 0.95
        let sleeveCuffBotY:   CGFloat = isPullovr ? 0.30 : 0.78
        let sleeveInnerX:     CGFloat = isPullovr ? 1.10 : 1.05
        let chestHalfW:       CGFloat = isWomen ? 0.95 : 1.10
        let waistHalfW:       CGFloat = isWomen ? 0.78 : 1.02
        let hipHalfW:         CGFloat = isWomen ? 0.95 : 1.08

        let p = UIBezierPath()

        // Top-right of collar
        p.move(to: CGPoint(x: collarTopHalfW, y: shoulderY))

        // Right shoulder slope
        p.addLine(to: CGPoint(x: shoulderHalfW, y: shoulderY - 0.04))

        // Outer sleeve top (curves out and down)
        p.addQuadCurve(
            to: CGPoint(x: sleeveOuterX, y: sleeveCuffTopY),
            controlPoint: CGPoint(x: shoulderHalfW + 0.45, y: shoulderY - 0.05)
        )

        // Sleeve cuff (outer bottom)
        p.addLine(to: CGPoint(x: sleeveOuterX - 0.06, y: sleeveCuffBotY))

        // Underarm (inner sleeve cuff up to armpit)
        p.addQuadCurve(
            to: CGPoint(x: sleeveInnerX, y: armpitY),
            controlPoint: CGPoint(x: sleeveInnerX + 0.12, y: sleeveCuffBotY + 0.08)
        )

        // Right side: armpit → chest → waist (gently curved for women)
        p.addQuadCurve(
            to: CGPoint(x: waistHalfW, y: waistY),
            controlPoint: CGPoint(x: chestHalfW, y: chestY)
        )

        // Waist → hip
        p.addQuadCurve(
            to: CGPoint(x: hipHalfW, y: hemY + 0.02),
            controlPoint: CGPoint(x: waistHalfW + 0.03, y: waistY - 0.6)
        )

        // Hem (slight curve)
        p.addQuadCurve(
            to: CGPoint(x: -hipHalfW, y: hemY + 0.02),
            controlPoint: CGPoint(x: 0, y: hemY - 0.06)
        )

        // Mirror up the left side ─────────────────────────────────────────
        p.addQuadCurve(
            to: CGPoint(x: -waistHalfW, y: waistY),
            controlPoint: CGPoint(x: -waistHalfW - 0.03, y: waistY - 0.6)
        )

        p.addQuadCurve(
            to: CGPoint(x: -sleeveInnerX, y: armpitY),
            controlPoint: CGPoint(x: -chestHalfW, y: chestY)
        )

        p.addQuadCurve(
            to: CGPoint(x: -sleeveOuterX + 0.06, y: sleeveCuffBotY),
            controlPoint: CGPoint(x: -sleeveInnerX - 0.12, y: sleeveCuffBotY + 0.08)
        )

        p.addLine(to: CGPoint(x: -sleeveOuterX, y: sleeveCuffTopY))

        p.addQuadCurve(
            to: CGPoint(x: -shoulderHalfW, y: shoulderY - 0.04),
            controlPoint: CGPoint(x: -shoulderHalfW - 0.45, y: shoulderY - 0.05)
        )

        p.addLine(to: CGPoint(x: -collarTopHalfW, y: shoulderY))

        // Collar dip (U-shape between collar tops)
        p.addCurve(
            to: CGPoint(x: collarTopHalfW, y: shoulderY),
            controlPoint1: CGPoint(x: -collarHalfW * 0.6, y: collarDipY - 0.02),
            controlPoint2: CGPoint(x:  collarHalfW * 0.6, y: collarDipY - 0.02)
        )

        p.close()
        return p
    }

    // MARK: - Color Helpers

    private static func averageBaseColor(of image: UIImage) -> UIColor {
        guard let cg = image.cgImage else { return .white }
        // Sample a single pixel from a "safe" non-decal corner of the texture (top-left).
        let sampleX = max(8, cg.width / 32)
        let sampleY = max(8, cg.height / 32)
        guard let data = cg.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return .white }

        let bpr = cg.bytesPerRow
        let bpp = cg.bitsPerPixel / 8
        let offset = sampleY * bpr + sampleX * bpp
        guard offset + 2 < CFDataGetLength(data) else { return .white }

        // Assume RGBA8 / BGRA8 — both expose R/G/B in the first three bytes
        // for typical UIImage-rendered bitmaps. Use a safe average heuristic.
        let r = CGFloat(bytes[offset]) / 255.0
        let g = CGFloat(bytes[offset + 1]) / 255.0
        let b = CGFloat(bytes[offset + 2]) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    private static func darken(_ color: UIColor, by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = max(0, 1 - amount)
        return UIColor(red: r * f, green: g * f, blue: b * f, alpha: a)
    }
}
