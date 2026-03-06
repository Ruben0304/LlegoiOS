import SwiftUI

// MARK: - Gradient Async Image
/// AsyncImage wrapper that extracts dominant colors and provides gradient
struct GradientAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    let cacheKey: String?
    let maxPixelSize: CGFloat
    @Binding var extractedGradient: ExtractedGradient
    @ViewBuilder let content: (Image, ExtractedGradient) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: (Error, ExtractedGradient) -> Failure

    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?

    private let fallbackImage: UIImage?
    private let fallbackGradient: ExtractedGradient

    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        extractedGradient: Binding<ExtractedGradient>,
        fallbackImage: UIImage? = nil,
        fallbackGradient: ExtractedGradient? = nil,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping (Error, ExtractedGradient) -> Failure
    ) {
        self.url = url
        self.cacheKey = cacheKey ?? url?.absoluteString
        self._extractedGradient = extractedGradient
        self.fallbackImage = fallbackImage
        self.fallbackGradient = fallbackGradient ?? .placeholder
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
        if let size = displaySize {
            let scale = UIScreen.main.scale
            self.maxPixelSize = min(max(size.width, size.height) * scale, 1400)
        } else {
            self.maxPixelSize = 800
        }
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image), extractedGradient)
            } else if let error = loadError {
                failure(error, fallbackGradient)
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url else {
            loadError = URLError(.badURL)
            extractedGradient = fallbackGradient
            return
        }

        let urlString = url.absoluteString

        // Check image cache first
        if let cachedImage = ImageCacheManager.shared.getImage(for: urlString) {
            self.loadedImage = cachedImage
            extractColorsFromImage(cachedImage)
            return
        }

        guard !isLoading else { return }
        isLoading = true

        let pixelSize = maxPixelSize

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadError = error
                    self.extractedGradient = self.fallbackGradient
                }
                return
            }

            guard let data = data,
                  let downloadedImage = ImageCacheManager.shared.decodeImageForDisplay(from: data, maxPixelSize: pixelSize) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadError = URLError(.cannotDecodeContentData)
                    self.extractedGradient = self.fallbackGradient
                }
                return
            }

            // Cache and display on main thread
            ImageCacheManager.shared.setImage(downloadedImage, for: urlString)
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadedImage = downloadedImage
                self.extractColorsFromImage(downloadedImage)
            }
        }.resume()
    }

    private func extractColorsFromImage(_ image: UIImage) {
        ImageColorExtractor.shared.extractColors(
            from: image,
            cacheKey: cacheKey
        ) { gradient in
            self.extractedGradient = gradient
        }
    }
}

// MARK: - Simplified Initializers

extension GradientAsyncImage where Failure == EmptyView {
    /// Initializer without failure view - uses placeholder on error
    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        extractedGradient: Binding<ExtractedGradient>,
        fallbackGradient: ExtractedGradient? = nil,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            cacheKey: cacheKey,
            displaySize: displaySize,
            extractedGradient: extractedGradient,
            fallbackImage: nil,
            fallbackGradient: fallbackGradient,
            content: content,
            placeholder: placeholder,
            failure: { _, _ in EmptyView() }
        )
    }
}

extension GradientAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView>, Failure == EmptyView {
    /// Minimal initializer with default placeholder
    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        extractedGradient: Binding<ExtractedGradient>,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content
    ) {
        self.init(
            url: url,
            cacheKey: cacheKey,
            displaySize: displaySize,
            extractedGradient: extractedGradient,
            fallbackImage: nil,
            fallbackGradient: nil,
            content: content,
            placeholder: { ProgressView() },
            failure: { _, _ in EmptyView() }
        )
    }
}

// MARK: - Simple Gradient Image (without binding, just extracts colors)

/// Simple version that just extracts gradient without requiring a binding
struct SimpleGradientAsyncImage<Content: View>: View {
    let url: URL?
    let cacheKey: String?
    let maxPixelSize: CGFloat
    @ViewBuilder let content: (Image, ExtractedGradient) -> Content

    @State private var loadedImage: UIImage?
    @State private var extractedGradient: ExtractedGradient = .placeholder
    @State private var isLoading = false

    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content
    ) {
        self.url = url
        self.cacheKey = cacheKey ?? url?.absoluteString
        self.content = content
        if let size = displaySize {
            let scale = UIScreen.main.scale
            self.maxPixelSize = min(max(size.width, size.height) * scale, 1400)
        } else {
            self.maxPixelSize = 800
        }
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image), extractedGradient)
            } else {
                ProgressView()
                    .onAppear { loadImage() }
            }
        }
    }

    private func loadImage() {
        guard let url = url else { return }
        let urlString = url.absoluteString

        if let cachedImage = ImageCacheManager.shared.getImage(for: urlString) {
            self.loadedImage = cachedImage
            extractColors(from: cachedImage)
            return
        }

        guard !isLoading else { return }
        isLoading = true

        let pixelSize = maxPixelSize

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = ImageCacheManager.shared.decodeImageForDisplay(from: data, maxPixelSize: pixelSize) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            ImageCacheManager.shared.setImage(image, for: urlString)
            DispatchQueue.main.async {
                self.isLoading = false
                self.loadedImage = image
                self.extractColors(from: image)
            }
        }.resume()
    }

    private func extractColors(from image: UIImage) {
        ImageColorExtractor.shared.extractColors(
            from: image,
            cacheKey: cacheKey
        ) { gradient in
            self.extractedGradient = gradient
        }
    }
}

// MARK: - Gradient Background View
/// Convenience view that shows only the gradient background
struct GradientAsyncBackground: View {
    let url: URL?
    let cacheKey: String?
    @Binding var gradient: ExtractedGradient

    @State private var hasLoaded = false

    var body: some View {
        gradient.linearGradient
            .onAppear {
                guard !hasLoaded else { return }
                hasLoaded = true
                loadAndExtract()
            }
    }

    private func loadAndExtract() {
        guard let url = url else { return }
        let urlString = url.absoluteString

        if let cachedImage = ImageCacheManager.shared.getImage(for: urlString) {
            extractColors(from: cachedImage)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = ImageCacheManager.shared.decodeImageForDisplay(from: data, maxPixelSize: 200) else { return }
            ImageCacheManager.shared.setImage(image, for: urlString)
            DispatchQueue.main.async {
                extractColors(from: image)
            }
        }.resume()
    }

    private func extractColors(from image: UIImage) {
        ImageColorExtractor.shared.extractColors(
            from: image,
            cacheKey: cacheKey ?? url?.absoluteString
        ) { extractedGradient in
            self.gradient = extractedGradient
        }
    }
}

// MARK: - Gradient Extraction from Asset

extension ExtractedGradient {
    /// Extract gradient from a named asset image (result is cached after first call)
    static func fromAsset(named name: String) -> ExtractedGradient {
        let cacheKey = "asset_\(name)"
        // Use the extractor's own cache — avoids recomputing on every card creation
        if let cached = ImageColorExtractor.shared.cachedGradient(for: cacheKey) {
            return cached
        }
        guard let image = UIImage(named: name) else {
            return .placeholder
        }
        let gradient = ImageColorExtractor.shared.extractColors(from: image)
        ImageColorExtractor.shared.cacheGradient(gradient, for: cacheKey)
        return gradient
    }

    /// Extract gradient asynchronously from asset
    static func fromAsset(named name: String, completion: @escaping @Sendable (ExtractedGradient) -> Void) {
        guard let image = UIImage(named: name) else {
            completion(.placeholder)
            return
        }
        ImageColorExtractor.shared.extractColors(from: image, cacheKey: "asset_\(name)") { gradient in
            completion(gradient)
        }
    }
}
