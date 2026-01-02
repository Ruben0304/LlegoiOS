import SwiftUI

// MARK: - Gradient Async Image
/// AsyncImage wrapper that extracts dominant colors and provides gradient
struct GradientAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    let cacheKey: String?
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

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    self.loadError = error
                    self.extractedGradient = fallbackGradient
                    return
                }

                guard let data = data, let downloadedImage = UIImage(data: data) else {
                    self.loadError = URLError(.cannotDecodeContentData)
                    self.extractedGradient = fallbackGradient
                    return
                }

                // Cache the image
                ImageCacheManager.shared.setImage(downloadedImage, for: urlString)
                self.loadedImage = downloadedImage
                extractColorsFromImage(downloadedImage)
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
        extractedGradient: Binding<ExtractedGradient>,
        fallbackGradient: ExtractedGradient? = nil,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            cacheKey: cacheKey,
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
        extractedGradient: Binding<ExtractedGradient>,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content
    ) {
        self.init(
            url: url,
            cacheKey: cacheKey,
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
    @ViewBuilder let content: (Image, ExtractedGradient) -> Content

    @State private var loadedImage: UIImage?
    @State private var extractedGradient: ExtractedGradient = .placeholder
    @State private var isLoading = false

    init(
        url: URL?,
        cacheKey: String? = nil,
        @ViewBuilder content: @escaping (Image, ExtractedGradient) -> Content
    ) {
        self.url = url
        self.cacheKey = cacheKey ?? url?.absoluteString
        self.content = content
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

        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data, let image = UIImage(data: data) {
                    ImageCacheManager.shared.setImage(image, for: urlString)
                    self.loadedImage = image
                    extractColors(from: image)
                }
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
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    ImageCacheManager.shared.setImage(image, for: urlString)
                    extractColors(from: image)
                }
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
    /// Extract gradient from a named asset image
    static func fromAsset(named name: String) -> ExtractedGradient {
        guard let image = UIImage(named: name) else {
            return .placeholder
        }
        return ImageColorExtractor.shared.extractColors(from: image)
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
