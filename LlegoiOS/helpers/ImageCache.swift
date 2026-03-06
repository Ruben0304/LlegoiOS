import SwiftUI
import CryptoKit
import ImageIO

// MARK: - Image Cache Manager
final class ImageCacheManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ImageCacheManager()

    // Memory cache (fast access)
    private let memoryCache = NSCache<NSString, CachedImage>()

    // Disk cache directory
    private let diskCacheURL: URL

    // Cache metadata (ETags, expiration dates)
    private let metadataURL: URL
    private var metadata: [String: ImageMetadata] = [:]

    // Queue for thread-safe operations
    private let ioQueue = DispatchQueue(label: "com.llego.imagecache.io", qos: .utility)
    private let metadataQueue = DispatchQueue(label: "com.llego.imagecache.metadata", qos: .utility)

    // Cache configuration
    private let maxMemoryCacheCount = 100
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100 MB
    private let maxDiskCacheSize = 300 * 1024 * 1024 // 300 MB
    private let defaultCacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 días
    private let defaultMaxPixelSize: CGFloat = 1400

    private init() {
        // Configure memory cache
        memoryCache.countLimit = maxMemoryCacheCount
        memoryCache.totalCostLimit = maxMemoryCacheSize

        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDirectory.appendingPathComponent("LlegoImageCache", isDirectory: true)
        metadataURL = diskCacheURL.appendingPathComponent("metadata.plist")

        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Load metadata
        loadMetadata()

        // Clean expired cache on init
        cleanExpiredCache()

        // Register for memory warnings
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
    }

    // MARK: - Public Interface

    /// Get image from cache (memory or disk) — may do disk I/O, avoid on main thread
    func getImage(for key: String) -> UIImage? {
        if let mem = getMemoryImage(for: key) { return mem }
        return getImageFromDisk(for: key, maxPixelSize: nil)
    }

    /// Get image from memory cache only — safe to call on main thread
    func getMemoryImage(for key: String) -> UIImage? {
        let cacheKey = key as NSString
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            if cachedImage.expirationDate > Date() {
                return cachedImage.image
            } else {
                memoryCache.removeObject(forKey: cacheKey)
            }
        }
        return nil
    }

    /// Get image from disk cache, decoding at the given pixel size — call on background thread
    func getImageFromDisk(for key: String, maxPixelSize: CGFloat?) -> UIImage? {
        guard let diskImage = loadImageFromDisk(key: key, maxPixelSize: maxPixelSize) else { return nil }
        // Promote to memory cache for future fast access
        let nsKey = key as NSString
        let cost = diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0
        let cached = CachedImage(image: diskImage, expirationDate: Date().addingTimeInterval(defaultCacheExpiration))
        memoryCache.setObject(cached, forKey: nsKey, cost: cost)
        return diskImage
    }

    /// Store image in cache with optional expiration
    func setImage(_ image: UIImage, for key: String, expiration: TimeInterval? = nil) {
        let cacheKey = key as NSString
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultCacheExpiration)
        let cachedImage = CachedImage(image: image, expirationDate: expirationDate)

        // 1. Store in memory cache
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        memoryCache.setObject(cachedImage, forKey: cacheKey, cost: cost)

        // 2. Store in disk cache asynchronously
        ioQueue.async { [weak self] in
            self?.saveImageToDisk(image, key: key, expirationDate: expirationDate)
        }
    }

    /// Store image with ETag for validation
    func setImage(_ image: UIImage, for key: String, etag: String?, expiration: TimeInterval? = nil) {
        setImage(image, for: key, expiration: expiration)

        if let etag = etag {
            metadataQueue.async { [weak self] in
                self?.metadata[key] = ImageMetadata(etag: etag, expirationDate: Date().addingTimeInterval(expiration ?? self?.defaultCacheExpiration ?? 0))
                self?.saveMetadata()
            }
        }
    }

    /// Get ETag for cached image (for conditional requests)
    func getETag(for key: String) -> String? {
        return metadata[key]?.etag
    }

    /// Check if image needs refresh based on expiration
    func needsRefresh(for key: String) -> Bool {
        guard let meta = metadata[key] else { return true }
        return meta.expirationDate < Date()
    }

    /// Check if image is expired beyond grace period (won't attempt background refresh)
    func isExpiredBeyondGracePeriod(for key: String) -> Bool {
        guard let meta = metadata[key] else { return true }
        let gracePeriod: TimeInterval = 30 * 24 * 60 * 60 // 30 días de gracia
        return meta.expirationDate.addingTimeInterval(gracePeriod) < Date()
    }

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clear all disk cache
    func clearDiskCache() {
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
            self.metadataQueue.async {
                self.metadata.removeAll()
                self.saveMetadata()
            }
        }
    }

    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        var size: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }

    // MARK: - Private Methods

    private func loadImageFromDisk(key: String, maxPixelSize: CGFloat? = nil) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(hash(key))

        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // Load and decode — caller is responsible for calling on a background thread
        guard let data = try? Data(contentsOf: fileURL),
              let image = decodeImageForDisplay(from: data, maxPixelSize: maxPixelSize) else {
            return nil
        }
        return image
    }

    private func saveImageToDisk(_ image: UIImage, key: String, expirationDate: Date) {
        let fileURL = diskCacheURL.appendingPathComponent(hash(key))

        // Compress image to save space
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }

        // Write to disk
        try? data.write(to: fileURL)

        // Update metadata
        metadataQueue.async { [weak self] in
            self?.metadata[key] = ImageMetadata(etag: nil, expirationDate: expirationDate)
            self?.saveMetadata()
        }

        // Clean cache if too large
        checkDiskCacheSize()
    }

    func decodeImageForDisplay(from data: Data, maxPixelSize: CGFloat? = nil) -> UIImage? {
        let targetPixelSize = maxPixelSize ?? defaultMaxPixelSize
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(targetPixelSize)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    private func checkDiskCacheSize() {
        let currentSize = getCacheSize()

        if currentSize > maxDiskCacheSize {
            // Remove oldest files until under limit
            var filesToRemove: [(URL, Date)] = []

            if let enumerator = FileManager.default.enumerator(at: diskCacheURL, includingPropertiesForKeys: [.creationDateKey]) {
                for case let fileURL as URL in enumerator {
                    if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate {
                        filesToRemove.append((fileURL, creationDate))
                    }
                }
            }

            // Sort by oldest first
            filesToRemove.sort { $0.1 < $1.1 }

            // Remove oldest 20%
            let removeCount = Int(Double(filesToRemove.count) * 0.2)
            for i in 0..<min(removeCount, filesToRemove.count) {
                try? FileManager.default.removeItem(at: filesToRemove[i].0)
            }
        }
    }

    private func cleanExpiredCache() {
        ioQueue.async { [weak self] in
            guard let self = self else { return }

            let now = Date()
            let maxAge: TimeInterval = 90 * 24 * 60 * 60 // 90 días - solo eliminar cosas MUY antiguas
            var keysToRemove: [String] = []

            self.metadataQueue.sync {
                for (key, meta) in self.metadata {
                    // Solo eliminar si está expirado hace MÁS de 90 días
                    if meta.expirationDate.addingTimeInterval(maxAge) < now {
                        keysToRemove.append(key)

                        // Remove file
                        let fileURL = self.diskCacheURL.appendingPathComponent(self.hash(key))
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                }

                // Remove from metadata
                keysToRemove.forEach { self.metadata.removeValue(forKey: $0) }
                if !keysToRemove.isEmpty {
                    self.saveMetadata()
                }
            }
        }
    }

    private func loadMetadata() {
        metadataQueue.sync {
            guard let data = try? Data(contentsOf: metadataURL),
                  let decoded = try? PropertyListDecoder().decode([String: ImageMetadata].self, from: data) else {
                return
            }
            metadata = decoded
        }
    }

    private func saveMetadata() {
        metadataQueue.async { [weak self] in
            guard let self = self,
                  let data = try? PropertyListEncoder().encode(self.metadata) else {
                return
            }
            try? data.write(to: self.metadataURL)
        }
    }

    private func hash(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Supporting Types

private final class CachedImage {
    let image: UIImage
    let expirationDate: Date

    init(image: UIImage, expirationDate: Date) {
        self.image = image
        self.expirationDate = expirationDate
    }
}

private struct ImageMetadata: Codable {
    let etag: String?
    let expirationDate: Date
}

// MARK: - Cached AsyncImage View with Loading and Failure States
struct CachedAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    let cacheKey: String? // Custom cache key (optional)
    /// Target display size in points - used to decode at the right pixel density and avoid waste.
    /// Pass the render size of the image container (e.g. CGSize(width: 140, height: 100)).
    /// Defaults to nil which uses the cache manager's default (1400px).
    let displaySize: CGSize?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var isNetworkError = false // Flag para errores de red
    @State private var loadTask: URLSessionDataTask?

    private var effectiveCacheKey: String {
        let urlKey = url?.absoluteString ?? ""
        if let cacheKey, !cacheKey.isEmpty {
            return urlKey.isEmpty ? cacheKey : "\(cacheKey)|\(urlKey)"
        }
        return urlKey
    }

    /// Pixel size to decode at: max(width, height) * screen scale, capped at 1400px.
    var maxPixelSize: CGFloat {
        guard let size = displaySize else { return 1400 }
        let scale = UIScreen.main.scale
        return min(max(size.width, size.height) * scale, 1400)
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if loadFailed && !isNetworkError {
                // Failure: mostrar shimmer en lugar del ícono raro
                failure()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onAppear {
            // Resetear estado de error al reaparecer (ej: scroll de vuelta)
            if loadFailed && image == nil {
                loadFailed = false
                isNetworkError = false
            }
        }
        .onDisappear {
            // Cancel ongoing download if view disappears
            loadTask?.cancel()
        }
        .onChange(of: effectiveCacheKey) { _, _ in
            resetAndReloadImage()
        }
    }

    private func loadImage() {
        guard let url = url else {
            loadFailed = true
            isNetworkError = false
            return
        }

        // Resetear estados al intentar cargar de nuevo
        loadFailed = false
        isNetworkError = false

        let cacheKey = effectiveCacheKey
        let targetPixelSize = maxPixelSize

        // 1. Memory cache — fast, sync on main thread (no disk/decode cost)
        if let memImage = ImageCacheManager.shared.getMemoryImage(for: cacheKey) {
            self.image = memImage
            if ImageCacheManager.shared.needsRefresh(for: cacheKey) &&
               !ImageCacheManager.shared.isExpiredBeyondGracePeriod(for: cacheKey) {
                downloadImageInBackground(from: url)
            }
            return
        }

        // 2. Disk cache + network — both potentially slow, do on background thread
        guard !isLoading else { return }
        isLoading = true

        let capturedUrl = url
        DispatchQueue.global(qos: .userInitiated).async {
            // Check disk cache (decode on background thread)
            if let diskImage = ImageCacheManager.shared.getImageFromDisk(for: cacheKey, maxPixelSize: targetPixelSize) {
                let needsRefresh = ImageCacheManager.shared.needsRefresh(for: cacheKey) &&
                                   !ImageCacheManager.shared.isExpiredBeyondGracePeriod(for: cacheKey)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.image = diskImage
                    if needsRefresh {
                        self.downloadImageInBackground(from: capturedUrl)
                    }
                }
                return
            }
            // Not in any cache — download from network
            DispatchQueue.main.async {
                self.downloadImage(from: capturedUrl)
            }
        }
    }

    private func resetAndReloadImage() {
        loadTask?.cancel()
        image = nil
        isLoading = false
        loadFailed = false
        isNetworkError = false
        loadImage()
    }

    private func downloadImage(from url: URL) {
        // Capture actor-isolated values before entering the URLSession closure
        let cacheKey = effectiveCacheKey
        let pixelSize = maxPixelSize

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        if let etag = ImageCacheManager.shared.getETag(for: cacheKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        loadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle errors on background thread before touching UI
            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain &&
                   (error.code == NSURLErrorNotConnectedToInternet ||
                    error.code == NSURLErrorTimedOut ||
                    error.code == NSURLErrorCannotConnectToHost ||
                    error.code == NSURLErrorNetworkConnectionLost) {
                    let cached = ImageCacheManager.shared.getImage(for: cacheKey)
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.isNetworkError = true
                        self.loadFailed = true
                        if let cachedImage = cached {
                            self.image = cachedImage
                            self.loadFailed = false
                        }
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isNetworkError = false
                    self.loadFailed = true
                }
                return
            }

            // 304 Not Modified
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 304 {
                let cached = ImageCacheManager.shared.getImage(for: cacheKey)
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let cachedImage = cached { self.image = cachedImage }
                }
                return
            }

            // Decode on background thread (expensive — keeps main thread free)
            if let data = data,
               let downloadedImage = ImageCacheManager.shared.decodeImageForDisplay(from: data, maxPixelSize: pixelSize) {
                let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String
                ImageCacheManager.shared.setImage(downloadedImage, for: cacheKey, etag: etag)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.image = downloadedImage
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.loadFailed = true
                }
            }
        }
        loadTask?.resume()
    }

    private func downloadImageInBackground(from url: URL) {
        // Capture actor-isolated values before entering the URLSession closure
        let cacheKey = effectiveCacheKey
        let pixelSize = maxPixelSize

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        if let etag = ImageCacheManager.shared.getETag(for: cacheKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError?,
               error.domain == NSURLErrorDomain &&
               (error.code == NSURLErrorNotConnectedToInternet ||
                error.code == NSURLErrorTimedOut ||
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorNetworkConnectionLost) {
                return
            }

            // Decode on background thread, update cache and UI
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 304,
               let downloadedImage = ImageCacheManager.shared.decodeImageForDisplay(from: data, maxPixelSize: pixelSize) {
                let etag = httpResponse.allHeaderFields["Etag"] as? String
                ImageCacheManager.shared.setImage(downloadedImage, for: cacheKey, etag: etag)
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }

    // MARK: - Initializers

    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.displaySize = displaySize
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
}

// MARK: - Convenience initializer without failure view
extension CachedAsyncImage where Failure == EmptyView {
    init(
        url: URL?,
        cacheKey: String? = nil,
        displaySize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.displaySize = displaySize
        self.content = content
        self.placeholder = placeholder
        self.failure = { EmptyView() }
    }
}

// MARK: - Convenience initializer to match AsyncImage API
extension CachedAsyncImage where Content == Image, Placeholder == AnyView, Failure == EmptyView {
    init(url: URL?, cacheKey: String? = nil, displaySize: CGSize? = nil, @ViewBuilder content: @escaping (Image) -> Image) {
        self.url = url
        self.cacheKey = cacheKey
        self.displaySize = displaySize
        self.content = content
        self.placeholder = {
            AnyView(ProgressView())
        }
        self.failure = { EmptyView() }
    }
}
