import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class TshirtCustomizerViewModel: ObservableObject {

    // MARK: - Published State

    @Published var garmentType: GarmentType = .tshirt
    @Published var gender: GarmentGender = .men
    @Published var selectedColor: ShirtColorOption = ShirtColorOption.presets.first!
    @Published var customColor: Color? = nil

    @Published private(set) var decals: [Decal] = []
    @Published var selectedDecalID: UUID? = nil

    /// Texture composited (color base + decals) used as the shirt's diffuse material.
    @Published private(set) var compositeTexture: UIImage = UIImage()

    /// Increment when the silhouette must be rebuilt.
    @Published private(set) var shapeVersion: Int = 0

    // MARK: - Constants

    static let textureSize = CGSize(width: 1024, height: 1024)
    /// Region in the texture where decals can live (front of the chest).
    static let designRect = CGRect(x: 256, y: 220, width: 512, height: 560)

    // MARK: - Init

    init() {
        regenerateTexture()
    }

    // MARK: - Derived

    var selectedDecal: Decal? {
        guard let id = selectedDecalID else { return nil }
        return decals.first(where: { $0.id == id })
    }

    var effectiveBaseUIColor: UIColor {
        if let custom = customColor {
            return UIColor(custom)
        }
        return selectedColor.uiColor
    }

    var effectiveBaseColor: Color {
        Color(uiColor: effectiveBaseUIColor)
    }

    // MARK: - Mutations

    func setGarmentType(_ t: GarmentType) {
        guard t != garmentType else { return }
        garmentType = t
        shapeVersion &+= 1
    }

    func setGender(_ g: GarmentGender) {
        guard g != gender else { return }
        gender = g
        shapeVersion &+= 1
    }

    func setPresetColor(_ c: ShirtColorOption) {
        customColor = nil
        selectedColor = c
        regenerateTexture()
    }

    func setCustomColor(_ color: Color) {
        customColor = color
        regenerateTexture()
    }

    func addDecal(_ image: UIImage) {
        let normalized = normalizeOrientation(image)
        let new = Decal(image: normalized)
        decals.append(new)
        selectedDecalID = new.id
        regenerateTexture()
    }

    func removeSelectedDecal() {
        guard let id = selectedDecalID else { return }
        decals.removeAll { $0.id == id }
        selectedDecalID = decals.last?.id
        regenerateTexture()
    }

    func update(decalID: UUID, mutate: (inout Decal) -> Void) {
        guard let idx = decals.firstIndex(where: { $0.id == decalID }) else { return }
        mutate(&decals[idx])
        regenerateTexture()
    }

    func bringToFront(decalID: UUID) {
        guard let idx = decals.firstIndex(where: { $0.id == decalID }) else { return }
        let d = decals.remove(at: idx)
        decals.append(d)
        selectedDecalID = decalID
    }

    func sendToBack(decalID: UUID) {
        guard let idx = decals.firstIndex(where: { $0.id == decalID }) else { return }
        let d = decals.remove(at: idx)
        decals.insert(d, at: 0)
    }

    // MARK: - Texture Compositing

    func regenerateTexture() {
        let size = Self.textureSize
        let baseColor = effectiveBaseUIColor

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { ctx in
            // 1. Base color
            baseColor.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            // 2. Subtle fabric grain
            drawFabricGrain(in: CGRect(origin: .zero, size: size))

            // 3. Decals
            for decal in decals {
                drawDecal(decal, in: Self.designRect)
            }
        }

        compositeTexture = image
    }

    private func drawFabricGrain(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.setBlendMode(.multiply)
        let dot = UIColor(white: 0, alpha: 0.018).cgColor
        ctx.setFillColor(dot)
        var seeded = SystemRandomNumberGenerator()
        for _ in 0..<1200 {
            let x = CGFloat.random(in: rect.minX..<rect.maxX, using: &seeded)
            let y = CGFloat.random(in: rect.minY..<rect.maxY, using: &seeded)
            let r = CGFloat.random(in: 0.4..<1.4, using: &seeded)
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
        }
        // Soft top highlight
        if let space = CGColorSpace(name: CGColorSpace.sRGB),
           let gradient = CGGradient(colorsSpace: space,
                                     colors: [UIColor(white: 1, alpha: 0.06).cgColor,
                                              UIColor(white: 1, alpha: 0).cgColor] as CFArray,
                                     locations: [0, 1]) {
            ctx.setBlendMode(.screen)
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.midX, y: rect.minY),
                                   end:   CGPoint(x: rect.midX, y: rect.midY),
                                   options: [])
        }
        ctx.restoreGState()
    }

    private func drawDecal(_ decal: Decal, in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let imgSize = decal.image.size
        guard imgSize.width > 0, imgSize.height > 0 else { return }
        let aspect = imgSize.width / imgSize.height
        let widthOnCanvas  = rect.width * decal.scale
        let heightOnCanvas = widthOnCanvas / aspect
        let centerX = rect.minX + decal.position.x * rect.width
        let centerY = rect.minY + decal.position.y * rect.height

        ctx.saveGState()
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: CGFloat(decal.rotation.radians))
        let drawRect = CGRect(
            x: -widthOnCanvas / 2,
            y: -heightOnCanvas / 2,
            width: widthOnCanvas,
            height: heightOnCanvas
        )
        decal.image.draw(in: drawRect, blendMode: .normal, alpha: CGFloat(decal.opacity))
        ctx.restoreGState()
    }

    /// Re-render UIImage to .up orientation (PhotosPicker returns oriented bitmaps that confuse CG drawing).
    private func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
