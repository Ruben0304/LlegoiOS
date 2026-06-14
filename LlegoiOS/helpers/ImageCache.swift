import SwiftUI
import CryptoKit

// MARK: - Image Cache Manager
final class ImageCacheManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private let urlCache: URLCache
    private let fileManager = FileManager.default
    private let diskCacheURL: URL

    private init() {
        // Configure memory cache
        cache.countLimit = 100 // max 100 images
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        // Configure URL cache (used by URLSession / AsyncImage)
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB memory
        let diskCapacity = 200 * 1024 * 1024 // 200 MB disk
        urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache

        // Persistent on-disk image cache. Survives app restarts regardless of
        // server cache headers — critical on slow/intermittent connections so
        // images are not re-downloaded every session.
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = caches.appendingPathComponent("LlegoImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    private func diskPath(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let fileName = digest.map { String(format: "%02x", $0) }.joined()
        return diskCacheURL.appendingPathComponent(fileName)
    }

    func getImage(for key: String) -> UIImage? {
        if let memoryImage = cache.object(forKey: key as NSString) {
            return memoryImage
        }
        // Fall back to disk; promote back into memory on hit.
        let path = diskPath(for: key)
        if let data = try? Data(contentsOf: path), let image = UIImage(data: data) {
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        return nil
    }

    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    /// Store both in memory and on disk for cross-session persistence.
    func store(_ data: Data, image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
        try? data.write(to: diskPath(for: key), options: .atomic)
    }
}

// MARK: - Cached AsyncImage View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url else { return }
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
                    // Cache the image in memory + disk for cross-session persistence
                    ImageCacheManager.shared.store(data, image: downloadedImage, for: urlString)
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}

// MARK: - Convenience initializer to match AsyncImage API
extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Image) {
        self.url = url
        self.content = content
        self.placeholder = {
            AnyView(ProgressView())
        }
    }
}
