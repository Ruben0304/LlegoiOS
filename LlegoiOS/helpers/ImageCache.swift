import SwiftUI
import CryptoKit

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

    /// Get image from cache (memory or disk)
    func getImage(for key: String) -> UIImage? {
        let cacheKey = key as NSString

        // 1. Check memory cache first (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            // Check if expired
            if cachedImage.expirationDate > Date() {
                return cachedImage.image
            } else {
                // Remove expired image from memory
                memoryCache.removeObject(forKey: cacheKey)
            }
        }

        // 2. Check disk cache
        if let diskImage = loadImageFromDisk(key: key) {
            // Store in memory cache for faster access next time
            let cost = diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0
            let cachedImage = CachedImage(
                image: diskImage,
                expirationDate: Date().addingTimeInterval(defaultCacheExpiration)
            )
            memoryCache.setObject(cachedImage, forKey: cacheKey, cost: cost)
            return diskImage
        }

        return nil
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

    private func loadImageFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(hash(key))

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // NO eliminar imágenes expiradas - permitir uso offline
        // Solo marcar para refresh en background si hay conexión
        // Las imágenes vencidas se limpian solo durante cleanExpiredCache() al iniciar

        // Load image
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
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
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var isNetworkError = false // Flag para errores de red
    @State private var loadTask: URLSessionDataTask?

    private var effectiveCacheKey: String {
        cacheKey ?? url?.absoluteString ?? ""
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if loadFailed && !isNetworkError {
                // Solo mostrar failure si NO es error de red
                failure()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onDisappear {
            // Cancel ongoing download if view disappears
            loadTask?.cancel()
        }
    }

    private func loadImage() {
        guard let url = url else {
            print("❌ CachedAsyncImage: URL is nil")
            loadFailed = true
            isNetworkError = false
            return
        }

        print("🔍 CachedAsyncImage: Loading image from URL: \(url.absoluteString)")
        print("🔑 Cache Key: \(effectiveCacheKey.prefix(50))...")

        // Resetear estados al intentar cargar de nuevo
        loadFailed = false
        isNetworkError = false

        // 1. Check cache first (memory + disk)
        if let cachedImage = ImageCacheManager.shared.getImage(for: effectiveCacheKey) {
            print("✅ CachedAsyncImage: Found image in cache")
            // Mostrar imagen cacheada inmediatamente
            self.image = cachedImage

            // Background refresh SOLO si necesita refresh Y no está expirada hace más de 7 días
            // (para evitar recargar en modo offline)
            if ImageCacheManager.shared.needsRefresh(for: effectiveCacheKey) &&
               !ImageCacheManager.shared.isExpiredBeyondGracePeriod(for: effectiveCacheKey) {
                print("🔄 CachedAsyncImage: Image needs refresh, downloading in background")
                downloadImageInBackground(from: url)
            }
            return
        }

        print("⬇️ CachedAsyncImage: Image not in cache, downloading...")
        // 2. If not in cache, download
        guard !isLoading else { return }
        isLoading = true
        downloadImage(from: url)
    }

    private func downloadImage(from url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // Timeout de 10 segundos

        // Add conditional request headers if we have an ETag
        if let etag = ImageCacheManager.shared.getETag(for: effectiveCacheKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            print("🏷️ CachedAsyncImage: Using ETag for conditional request")
        }

        print("📡 CachedAsyncImage: Starting download...")
        loadTask = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                // Si hay error de red (offline), intentar cargar desde caché aunque esté "expirada"
                if let error = error as NSError? {
                    print("❌ CachedAsyncImage: Download error - \(error.localizedDescription)")
                    print("   Error domain: \(error.domain), code: \(error.code)")

                    // Errores de conexión (offline, timeout, etc)
                    if error.domain == NSURLErrorDomain &&
                       (error.code == NSURLErrorNotConnectedToInternet ||
                        error.code == NSURLErrorTimedOut ||
                        error.code == NSURLErrorCannotConnectToHost ||
                        error.code == NSURLErrorNetworkConnectionLost) {

                        print("🌐 CachedAsyncImage: Network error detected, trying to load from cache")
                        // Marcar como error de red
                        self.isNetworkError = true
                        self.loadFailed = true

                        // Intentar cargar desde caché sin importar expiración
                        if let cachedImage = ImageCacheManager.shared.getImage(for: self.effectiveCacheKey) {
                            print("✅ CachedAsyncImage: Loaded expired cache due to network error")
                            self.image = cachedImage
                            self.loadFailed = false
                            return
                        }

                        print("⚠️ CachedAsyncImage: No cache available for offline mode")
                        // Si no hay caché, quedarse en estado de loading/placeholder
                        // (no mostrar failure para errores de red sin caché)
                        return
                    }

                    // Otros errores (no de red) -> marcar como failed
                    print("⚠️ CachedAsyncImage: Non-network error, marking as failed")
                    self.isNetworkError = false
                    self.loadFailed = true
                    return
                }

                // Log response status
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 CachedAsyncImage: HTTP Status: \(httpResponse.statusCode)")
                    print("   Content-Type: \(httpResponse.allHeaderFields["Content-Type"] ?? "unknown")")
                    print("   Content-Length: \(httpResponse.allHeaderFields["Content-Length"] ?? "unknown")")
                }

                // Check for 304 Not Modified
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 304 {
                    print("♻️ CachedAsyncImage: 304 Not Modified - using cached version")
                    // Image hasn't changed, use cached version
                    if let cachedImage = ImageCacheManager.shared.getImage(for: self.effectiveCacheKey) {
                        self.image = cachedImage
                    }
                    return
                }

                if let data = data, let downloadedImage = UIImage(data: data) {
                    print("✅ CachedAsyncImage: Successfully downloaded and decoded image")
                    print("   Image size: \(downloadedImage.size)")
                    print("   Data size: \(data.count) bytes")

                    // Extract ETag from response
                    let etag = (response as? HTTPURLResponse)?.allHeaderFields["Etag"] as? String

                    // Cache the image with ETag
                    ImageCacheManager.shared.setImage(
                        downloadedImage,
                        for: self.effectiveCacheKey,
                        etag: etag
                    )

                    self.image = downloadedImage
                } else {
                    if let data = data {
                        print("❌ CachedAsyncImage: Failed to decode image data (\(data.count) bytes)")
                    } else {
                        print("❌ CachedAsyncImage: No data received")
                    }
                    self.loadFailed = true
                }
            }
        }
        loadTask?.resume()
    }

    private func downloadImageInBackground(from url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // Timeout más corto para background refresh

        if let etag = ImageCacheManager.shared.getETag(for: effectiveCacheKey) {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Si hay error de conexión, no hacer nada (silenciar el error)
            if let error = error as NSError?,
               error.domain == NSURLErrorDomain &&
               (error.code == NSURLErrorNotConnectedToInternet ||
                error.code == NSURLErrorTimedOut ||
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorNetworkConnectionLost) {
                // No hacer nada - ya tenemos la imagen cacheada mostrada
                return
            }

            // Don't update UI, just update cache
            if let data = data,
               let downloadedImage = UIImage(data: data),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 304 {

                let etag = httpResponse.allHeaderFields["Etag"] as? String
                ImageCacheManager.shared.setImage(
                    downloadedImage,
                    for: self.effectiveCacheKey,
                    etag: etag
                )

                // Actualizar la imagen mostrada con la nueva versión
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
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.cacheKey = cacheKey
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
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.content = content
        self.placeholder = placeholder
        self.failure = { EmptyView() }
    }
}

// MARK: - Convenience initializer to match AsyncImage API
extension CachedAsyncImage where Content == Image, Placeholder == AnyView, Failure == EmptyView {
    init(url: URL?, cacheKey: String? = nil, @ViewBuilder content: @escaping (Image) -> Image) {
        self.url = url
        self.cacheKey = cacheKey
        self.content = content
        self.placeholder = {
            AnyView(ProgressView())
        }
        self.failure = { EmptyView() }
    }
}
