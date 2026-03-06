import SwiftUI
import UIKit
import CoreGraphics
import CoreImage
import Metal

// MARK: - Extracted Gradient Result
struct ExtractedGradient: Sendable, Equatable {
    let colors: [Color]
    let primaryColor: Color
    let secondaryColor: Color

    var linearGradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var verticalGradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static let placeholder = ExtractedGradient(
        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
        primaryColor: Color.gray.opacity(0.3),
        secondaryColor: Color.gray.opacity(0.1)
    )
}

// MARK: - Image Color Extractor
final class ImageColorExtractor: @unchecked Sendable {

    static let shared = ImageColorExtractor()

    private let cache = NSCache<NSString, CachedGradient>()
    private let processingQueue = DispatchQueue(label: "com.llego.colorextractor", qos: .userInitiated)
    private let ciContext: CIContext?

    private init() {
        cache.countLimit = 100
        if let device = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: device)
        } else {
            ciContext = nil
        }
    }

    // MARK: - Cache wrapper (class for NSCache)
    private class CachedGradient {
        let gradient: ExtractedGradient
        init(_ gradient: ExtractedGradient) {
            self.gradient = gradient
        }
    }

    // MARK: - Public API

    /// Return a cached gradient if available, without doing any work
    func cachedGradient(for key: String) -> ExtractedGradient? {
        cache.object(forKey: key as NSString)?.gradient
    }

    /// Store a gradient result in cache
    func cacheGradient(_ gradient: ExtractedGradient, for key: String) {
        cache.setObject(CachedGradient(gradient), forKey: key as NSString)
    }

    /// Extract dominant colors from UIImage synchronously
    func extractColors(from image: UIImage, colorCount: Int = 2) -> ExtractedGradient {
        let colors = extractDominantColors(from: image, count: colorCount)

        guard colors.count >= 2 else {
            return ExtractedGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                primaryColor: colors.first ?? Color.gray.opacity(0.3),
                secondaryColor: colors.last ?? Color.gray.opacity(0.1)
            )
        }

        return ExtractedGradient(
            colors: colors,
            primaryColor: colors[0],
            secondaryColor: colors[1]
        )
    }

    /// Extract dominant colors asynchronously with caching
    func extractColors(
        from image: UIImage,
        cacheKey: String?,
        colorCount: Int = 2,
        completion: @escaping @Sendable (ExtractedGradient) -> Void
    ) {
        // Check cache first
        if let key = cacheKey,
           let cached = cache.object(forKey: key as NSString) {
            completion(cached.gradient)
            return
        }

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let gradient = self.extractColors(from: image, colorCount: colorCount)

            // Cache the result
            if let key = cacheKey {
                self.cache.setObject(CachedGradient(gradient), forKey: key as NSString)
            }

            DispatchQueue.main.async {
                completion(gradient)
            }
        }
    }

    /// Async/await version
    func extractColors(
        from image: UIImage,
        cacheKey: String? = nil,
        colorCount: Int = 2
    ) async -> ExtractedGradient {
        await withCheckedContinuation { continuation in
            extractColors(from: image, cacheKey: cacheKey, colorCount: colorCount) { gradient in
                continuation.resume(returning: gradient)
            }
        }
    }

    // MARK: - Core Algorithm

    private func extractDominantColors(from image: UIImage, count: Int) -> [Color] {
        if let fastColors = extractDominantColorsCI(from: image) {
            return fastColors.map { Color(uiColor: $0) }
        }
        return []
    }

    private func extractDominantColorsCI(from image: UIImage) -> [UIColor]? {
        guard let ciContext else { return nil }

        let ciImage: CIImage
        if let cgImage = image.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        } else {
            return nil
        }

        let extent = ciImage.extent
        guard extent.width > 2, extent.height > 2 else { return nil }

        let rectA = CGRect(
            x: extent.minX,
            y: extent.midY,
            width: extent.width * 0.55,
            height: extent.height * 0.45
        )
        let rectB = CGRect(
            x: extent.midX - (extent.width * 0.1),
            y: extent.minY,
            width: extent.width * 0.6,
            height: extent.height * 0.55
        )

        guard let colorA = averageColor(in: ciImage, rect: rectA, context: ciContext),
              let colorB = averageColor(in: ciImage, rect: rectB, context: ciContext) else {
            return nil
        }

        return [colorA, colorB].sorted {
            let a = $0.hsb
            let b = $1.hsb
            return (a.saturation * a.brightness) > (b.saturation * b.brightness)
        }
    }

    private func averageColor(in image: CIImage, rect: CGRect, context: CIContext) -> UIColor? {
        let cropRect = rect.intersection(image.extent)
        guard !cropRect.isEmpty else { return nil }

        let region = image.cropped(to: cropRect)
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(region, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: region.extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let alpha = CGFloat(bitmap[3]) / 255.0
        guard alpha > 0.05 else { return nil }

        return UIColor(
            red: CGFloat(bitmap[0]) / 255.0,
            green: CGFloat(bitmap[1]) / 255.0,
            blue: CGFloat(bitmap[2]) / 255.0,
            alpha: 1.0
        )
    }

    private func resizeImage(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

    private func getPixelData(from cgImage: CGImage?) -> [PixelColor]? {
        guard let cgImage = cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var colors: [PixelColor] = []
        colors.reserveCapacity(width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = pixelData[offset]
                let g = pixelData[offset + 1]
                let b = pixelData[offset + 2]
                let a = pixelData[offset + 3]

                // Skip transparent or near-white/black pixels
                if a > 200 && !isNearWhiteOrBlack(r: r, g: g, b: b) {
                    colors.append(PixelColor(r: r, g: g, b: b))
                }
            }
        }

        return colors
    }

    private func isNearWhiteOrBlack(r: UInt8, g: UInt8, b: UInt8) -> Bool {
        let brightness = (Int(r) + Int(g) + Int(b)) / 3
        return brightness < 20 || brightness > 235
    }

    private func clusterColors(pixelData: [PixelColor], clusterCount: Int) -> [UIColor] {
        guard !pixelData.isEmpty else { return [] }

        // Simple k-means clustering
        var centroids = initializeCentroids(from: pixelData, count: clusterCount)

        for _ in 0..<5 { // 5 iterations usually enough for small images
            var clusters: [[PixelColor]] = Array(repeating: [], count: clusterCount)

            // Assign pixels to nearest centroid
            for pixel in pixelData {
                var minDistance = Double.infinity
                var nearestCluster = 0

                for (index, centroid) in centroids.enumerated() {
                    let distance = pixel.distance(to: centroid)
                    if distance < minDistance {
                        minDistance = distance
                        nearestCluster = index
                    }
                }

                clusters[nearestCluster].append(pixel)
            }

            // Update centroids
            for (index, cluster) in clusters.enumerated() {
                if !cluster.isEmpty {
                    centroids[index] = averageColor(of: cluster)
                }
            }
        }

        return centroids.map { $0.uiColor }
    }

    private func initializeCentroids(from pixels: [PixelColor], count: Int) -> [PixelColor] {
        guard !pixels.isEmpty else { return [] }

        // Use k-means++ initialization for better results
        var centroids: [PixelColor] = []

        // First centroid: random pixel
        if let first = pixels.randomElement() {
            centroids.append(first)
        }

        // Remaining centroids: choose pixels far from existing centroids
        while centroids.count < count && centroids.count < pixels.count {
            var maxDistance: Double = 0
            var bestPixel = pixels[0]

            for pixel in pixels {
                let minDistToCentroid = centroids.map { pixel.distance(to: $0) }.min() ?? 0
                if minDistToCentroid > maxDistance {
                    maxDistance = minDistToCentroid
                    bestPixel = pixel
                }
            }

            centroids.append(bestPixel)
        }

        return centroids
    }

    private func averageColor(of pixels: [PixelColor]) -> PixelColor {
        guard !pixels.isEmpty else { return PixelColor(r: 128, g: 128, b: 128) }

        var totalR: Int = 0
        var totalG: Int = 0
        var totalB: Int = 0

        for pixel in pixels {
            totalR += Int(pixel.r)
            totalG += Int(pixel.g)
            totalB += Int(pixel.b)
        }

        let count = pixels.count
        return PixelColor(
            r: UInt8(totalR / count),
            g: UInt8(totalG / count),
            b: UInt8(totalB / count)
        )
    }
}

// MARK: - Helper Types

private struct PixelColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    var uiColor: UIColor {
        UIColor(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }

    var hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return (h, s, b)
    }

    func distance(to other: PixelColor) -> Double {
        let dr = Double(Int(r) - Int(other.r))
        let dg = Double(Int(g) - Int(other.g))
        let db = Double(Int(b) - Int(other.b))
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    var hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        return (h, s, b)
    }
}
