import SwiftUI

// MARK: - Image Cache Manager
final class ImageCacheManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private let urlCache: URLCache

    private init() {
        // Configure memory cache
        cache.countLimit = 100 // max 100 images
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        // Configure disk cache
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB memory
        let diskCapacity = 200 * 1024 * 1024 // 200 MB disk
        urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache
    }

    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - Cached AsyncImage View with Loading and Failure States
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if loadFailed {
                failure()
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
            loadFailed = true
            return
        }
        let urlString = url.absoluteString

        // Check memory cache first
        if let cachedImage = ImageCacheManager.shared.getImage(for: urlString) {
            self.image = cachedImage
            return
        }

        // If not in cache, download
        guard !isLoading else { return }
        isLoading = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let data = data, let downloadedImage = UIImage(data: data) {
                    // Cache the image
                    ImageCacheManager.shared.setImage(downloadedImage, for: urlString)
                    self.image = downloadedImage
                } else {
                    self.loadFailed = true
                }
            }
        }.resume()
    }
}

// MARK: - Convenience initializer without failure view
extension CachedAsyncImage where Failure == EmptyView {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = { EmptyView() }
    }
}

// MARK: - Convenience initializer to match AsyncImage API
extension CachedAsyncImage where Content == Image, Placeholder == AnyView, Failure == EmptyView {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Image) {
        self.url = url
        self.content = content
        self.placeholder = {
            AnyView(ProgressView())
        }
        self.failure = { EmptyView() }
    }
}
