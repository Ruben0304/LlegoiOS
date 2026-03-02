//
//  ProductCacheManager.swift
//  LlegoiOS
//

import Foundation

struct CachedProduct: Codable {
    let id: String
    let name: String
    let branchId: String
    let categoryId: String?
    let price: Double
    let currency: String
    let imageUrl: String
    let timestamp: Date
    let source: CacheSource
}

enum CacheSource: String, Codable {
    case viewed
    case cart
    case branch
}

@MainActor
final class ProductCacheManager {
    static let shared = ProductCacheManager()
    
    private let maxCacheSize = 200
    private let cacheTTLDays = 7
    private let cacheFileName = "llego_product_cache.json"
    
    private(set) var cachedProducts: [CachedProduct] = []
    
    private init() {
        load()
        clearExpired()
    }
    
    func addProduct(_ product: CachedProduct) {
        if let index = cachedProducts.firstIndex(where: { $0.id == product.id }) {
            cachedProducts[index] = product
        } else {
            cachedProducts.append(product)
        }
        evictIfNeeded()
        persist()
    }
    
    func addProducts(_ products: [CachedProduct]) {
        for product in products {
            if let index = cachedProducts.firstIndex(where: { $0.id == product.id }) {
                cachedProducts[index] = product
            } else {
                cachedProducts.append(product)
            }
        }
        evictIfNeeded()
        persist()
    }
    
    func getProducts(limit: Int = 200) -> [CachedProduct] {
        clearExpired()
        return Array(cachedProducts.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
    
    func clearExpired() {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -cacheTTLDays, to: Date()) ?? Date()
        let beforeCount = cachedProducts.count
        cachedProducts.removeAll { $0.timestamp < expirationDate }
        if cachedProducts.count != beforeCount {
            persist()
        }
    }
    
    func clearAll() {
        cachedProducts.removeAll()
        persist()
    }
    
    private func persist() {
        guard let url = cacheFileURL() else { return }
        do {
            let data = try JSONEncoder().encode(cachedProducts)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ [ProductCacheManager] Failed to persist: \(error.localizedDescription)")
        }
    }
    
    private func load() {
        guard let url = cacheFileURL(), FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            cachedProducts = try JSONDecoder().decode([CachedProduct].self, from: data)
            print("✅ [ProductCacheManager] Loaded \(cachedProducts.count) products from cache")
        } catch {
            print("❌ [ProductCacheManager] Failed to load: \(error.localizedDescription)")
            cachedProducts = []
        }
    }
    
    private func evictIfNeeded() {
        guard cachedProducts.count > maxCacheSize else { return }
        cachedProducts.sort { $0.timestamp > $1.timestamp }
        cachedProducts = Array(cachedProducts.prefix(maxCacheSize))
    }
    
    private func cacheFileURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
}
