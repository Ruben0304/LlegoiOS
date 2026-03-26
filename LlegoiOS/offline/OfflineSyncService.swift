//
//  OfflineSyncService.swift
//  LlegoiOS
//
//  Servicio singleton que maneja la sincronización de datos locales
//  y descarga de imágenes desde el backend.
//

import Foundation
import SwiftData
import Apollo
import Combine

// MARK: - Sync State

enum SyncStatus: Equatable {
    case idle
    case syncing(SyncPhase)
    case done
    case failed(String)
}

enum SyncPhase: String, Equatable {
    case businesses = "Sincronizando negocios..."
    case products = "Sincronizando productos..."
    case images = "Descargando imágenes..."
    case embeddings = "Indexando datos..."
}

// MARK: - Image Quality

enum OfflineImageQuality: String, CaseIterable {
    case baja = "Baja (100×100)"
    case original = "Original"

    var displayName: String { rawValue }
}

// MARK: - OfflineSyncService

@MainActor
final class OfflineSyncService: ObservableObject {
    static let shared = OfflineSyncService()

    @Published var syncStatus: SyncStatus = .idle
    @Published var hasLocalData: Bool = false
    @Published var lastSyncDate: Date? = nil
    @Published var productCount: Int = 0
    @Published var businessCount: Int = 0
    /// Progreso de indexación vectorial 0.0–1.0 (solo durante fase .embeddings)
    @Published var embeddingProgress: Double = 0.0

    private let apolloClient = ApolloClientManager.shared.apollo
    private var modelContext: ModelContext?

    private init() {}

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshStats()
    }

    // MARK: - Stats

    func refreshStats() {
        guard let ctx = modelContext else { return }
        do {
            let products = try ctx.fetch(FetchDescriptor<LocalProduct>())
            let businesses = try ctx.fetch(FetchDescriptor<LocalBusiness>())
            let branches = try ctx.fetch(FetchDescriptor<LocalBranch>())
            productCount = products.count
            businessCount = businesses.count
            hasLocalData = productCount > 0 || businessCount > 0
            print("📊 refreshStats - Productos: \(productCount), Negocios (LocalBusiness): \(businessCount), Sucursales (LocalBranch): \(branches.count), hasLocalData: \(hasLocalData)")

            // Cargar fecha de última sincronización
            let productsKey = SyncMetadata.productsKey
            let metaDescriptor = FetchDescriptor<SyncMetadata>(
                predicate: #Predicate { $0.key == productsKey }
            )
            lastSyncDate = try ctx.fetch(metaDescriptor).first?.lastSyncDate
        } catch {
            print("❌ OfflineSyncService - Error fetching stats: \(error)")
        }
    }

    // MARK: - Full Sync (datos + imágenes opcionales)

    func syncAll(downloadImages: Bool = false, imageQuality: OfflineImageQuality = .baja) async {
        guard syncStatus == .idle else { return }

        do {
            // 1. Sync negocios y branches
            syncStatus = .syncing(.businesses)
            try await syncBusinesses()

            // 2. Sync productos
            syncStatus = .syncing(.products)
            try await syncProducts()

            // 3. Indexar embeddings
            syncStatus = .syncing(.embeddings)
            await buildEmbeddings()

            // 4. Imágenes (opcional)
            if downloadImages {
                syncStatus = .syncing(.images)
                try await syncImages(quality: imageQuality)
            }

            syncStatus = .done
            refreshStats()

            // Volver a idle después de un momento
            try await Task.sleep(nanoseconds: 2_000_000_000)
            syncStatus = .idle

        } catch {
            syncStatus = .failed(error.localizedDescription)
        }
    }

    // MARK: - Sync solo datos (negocios + productos + embeddings, sin imágenes)

    func syncDataOnly() async {
        guard syncStatus == .idle else { return }
        do {
            syncStatus = .syncing(.businesses)
            try await syncBusinesses()

            syncStatus = .syncing(.products)
            try await syncProducts()

            syncStatus = .syncing(.embeddings)
            await buildEmbeddings()

            syncStatus = .done
            refreshStats()
            try await Task.sleep(nanoseconds: 1_500_000_000)
            syncStatus = .idle
        } catch {
            syncStatus = .failed(error.localizedDescription)
        }
    }

    // MARK: - Sync solo imágenes

    func syncImagesOnly(quality: OfflineImageQuality) async {
        guard syncStatus == .idle else { return }
        do {
            syncStatus = .syncing(.images)
            try await syncImages(quality: quality)
            syncStatus = .done
            refreshStats()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            syncStatus = .idle
        } catch {
            syncStatus = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private: Sync Businesses

    private func syncBusinesses() async throws {
        print("🏪 syncBusinesses - Iniciando...")
        guard modelContext != nil else {
            print("❌ syncBusinesses - modelContext es nil")
            throw OfflineError.noContext
        }

        return try await withCheckedThrowingContinuation { continuation in
            print("🏪 syncBusinesses - Lanzando query Apollo...")
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncBusinessesWithBranchesQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                print("🏪 syncBusinesses - Callback Apollo recibido, self nil: \(self == nil)")
                Task { @MainActor in
                    guard let self = self, let ctx = self.modelContext else { return }
                    switch result {
                    case .success(let graphQLResult):
                        print("🏪 syncBusinesses - graphQLResult recibido, data: \(graphQLResult.data != nil ? "OK" : "nil"), errors: \(graphQLResult.errors?.map { $0.message ?? "" } ?? [])")
                        guard let data = graphQLResult.data else {
                            print("⚠️ syncBusinesses - data es nil, abortando sin guardar")
                            continuation.resume()
                            return
                        }

                        print("🏪 syncBusinesses - Respuesta recibida: \(data.syncBusinessesWithBranches.count) negocios")

                        do {
                            // Borrar uno a uno para respetar relaciones inversas de SwiftData
                            let oldBranches = try ctx.fetch(FetchDescriptor<LocalBranch>())
                            oldBranches.forEach { ctx.delete($0) }
                            let oldBusinesses = try ctx.fetch(FetchDescriptor<LocalBusiness>())
                            oldBusinesses.forEach { ctx.delete($0) }
                            try ctx.save()
                            print("🗑️ syncBusinesses - Borrado previo OK (\(oldBusinesses.count) negocios, \(oldBranches.count) sucursales)")

                            var totalBranches = 0

                            for biz in data.syncBusinessesWithBranches {
                                let localBiz = LocalBusiness(
                                    id: biz.id,
                                    name: biz.name,
                                    globalRating: biz.globalRating,
                                    avatar: biz.avatar,
                                    avatarUrl: biz.avatarUrl,
                                    businessDescription: biz.description,
                                    tags: biz.tags ?? [],
                                    isActive: biz.isActive,
                                    createdAt: "\(biz.createdAt)"
                                )
                                ctx.insert(localBiz)

                                for branch in biz.branches {
                                    let lat = branch.coordinates.coordinates.count > 1
                                        ? branch.coordinates.coordinates[1] : 0.0
                                    let lon = branch.coordinates.coordinates.count > 0
                                        ? branch.coordinates.coordinates[0] : 0.0

                                    let localBranch = LocalBranch(
                                        id: branch.id,
                                        businessId: branch.businessId,
                                        name: branch.name,
                                        address: branch.address,
                                        latitude: lat,
                                        longitude: lon,
                                        phone: branch.phone,
                                        isActive: branch.isActive,
                                        status: branch.status,
                                        avatar: branch.avatar,
                                        avatarUrl: branch.avatarUrl,
                                        coverImage: branch.coverImage,
                                        coverUrl: branch.coverUrl,
                                        tipos: branch.tipos,
                                        deliveryRadius: branch.deliveryRadius,
                                        createdAt: "\(branch.createdAt)"
                                    )
                                    localBranch.business = localBiz
                                    ctx.insert(localBranch)
                                    totalBranches += 1
                                }
                            }

                            try ctx.save()
                            print("💾 syncBusinesses - Guardado OK: \(data.syncBusinessesWithBranches.count) negocios, \(totalBranches) sucursales")

                            // Verificar lo que quedó en BD
                            let savedBranches = (try? ctx.fetch(FetchDescriptor<LocalBranch>())) ?? []
                            let savedBusinesses = (try? ctx.fetch(FetchDescriptor<LocalBusiness>())) ?? []
                            print("🔍 syncBusinesses - En BD: \(savedBusinesses.count) negocios, \(savedBranches.count) sucursales")

                            self.updateMetadata(key: SyncMetadata.businessesKey, count: data.syncBusinessesWithBranches.count, ctx: ctx)
                            continuation.resume()
                        } catch {
                            print("❌ syncBusinesses - Error al guardar: \(error)")
                            continuation.resume(throwing: error)
                        }

                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Private: Sync Products

    private func syncProducts() async throws {
        guard modelContext != nil else { throw OfflineError.noContext }

        return try await withCheckedThrowingContinuation { continuation in
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncProductsQuery(availableOnly: .some(true)),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self = self, let ctx = self.modelContext else { return }
                    switch result {
                    case .success(let graphQLResult):
                        guard let data = graphQLResult.data else {
                            continuation.resume()
                            return
                        }

                        print("📦 syncProducts - Respuesta recibida: \(data.syncProducts.count) productos")

                        do {
                            try ctx.delete(model: LocalProduct.self)
                            try ctx.save()

                            for p in data.syncProducts {
                                let localProduct = LocalProduct(
                                    id: p.id,
                                    branchId: p.branchId,
                                    name: p.name,
                                    productDescription: p.description,
                                    weight: p.weight,
                                    price: p.price,
                                    currency: p.currency,
                                    image: p.image,
                                    imageUrl: p.imageUrl,
                                    availability: p.availability,
                                    categoryId: p.categoryId,
                                    createdAt: "\(p.createdAt)"
                                )
                                ctx.insert(localProduct)
                            }

                            try ctx.save()
                            print("💾 syncProducts - Guardado OK: \(data.syncProducts.count) productos")

                            let savedProducts = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
                            print("🔍 syncProducts - En BD: \(savedProducts.count) productos")

                            self.updateMetadata(key: SyncMetadata.productsKey, count: data.syncProducts.count, ctx: ctx)
                            continuation.resume()
                        } catch {
                            print("❌ syncProducts - Error al guardar: \(error)")
                            continuation.resume(throwing: error)
                        }

                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Private: Sync Images

    private func syncImages(quality: OfflineImageQuality) async throws {
        print("🖼️ syncImages - Iniciando (calidad: \(quality.rawValue))...")
        guard modelContext != nil else {
            print("❌ syncImages - modelContext es nil")
            throw OfflineError.noContext
        }

        let qualities: GraphQLNullable<[GraphQLEnum<LlegoAPI.ImageQuality>]>
        switch quality {
        case .baja:
            qualities = .some([.init(.baja)])
        case .original:
            qualities = .some([.init(.original)])
        }

        return try await withCheckedThrowingContinuation { continuation in
            print("🖼️ syncImages - Lanzando query Apollo...")
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncImagesQuery(
                    entityType: .none,
                    entityIds: .none,
                    qualities: qualities
                ),
                cachePolicy: .fetchIgnoringCacheData
            ) { [weak self] result in
                Task { @MainActor in
                    guard let self = self, let ctx = self.modelContext else { return }
                    switch result {
                    case .success(let graphQLResult):
                        print("🖼️ syncImages - Callback recibido, data: \(graphQLResult.data != nil ? "OK" : "nil"), errors: \(graphQLResult.errors?.map { $0.message ?? "" } ?? [])")
                        guard let data = graphQLResult.data else {
                            print("⚠️ syncImages - data es nil, abortando")
                            continuation.resume()
                            return
                        }

                        print("🖼️ syncImages - \(data.syncImages.count) imágenes recibidas")

                        // Actualizar/insertar registros de imágenes con URLs
                        var inserted = 0, updated = 0
                        for img in data.syncImages {
                            let imgId = "\(img.entityId)_\(img.entityType)"
                            let descriptor = FetchDescriptor<LocalImage>(
                                predicate: #Predicate { $0.id == imgId }
                            )
                            if let existing = try? ctx.fetch(descriptor).first {
                                existing.bajaUrl = img.urls.baja
                                existing.originalUrl = img.urls.original
                                updated += 1
                            } else {
                                let localImg = LocalImage(
                                    entityId: img.entityId,
                                    entityType: img.entityType,
                                    imagePath: img.imagePath,
                                    bajaUrl: img.urls.baja,
                                    originalUrl: img.urls.original
                                )
                                ctx.insert(localImg)
                                inserted += 1
                            }
                        }

                        do {
                            try ctx.save()
                            print("💾 syncImages - URLs guardadas OK (insertadas: \(inserted), actualizadas: \(updated))")
                        } catch {
                            print("❌ syncImages - Error al guardar URLs: \(error)")
                        }

                        // Descargar los datos de imagen en background
                        let imagesCopy = data.syncImages.map { img in
                            (entityId: img.entityId, entityType: img.entityType,
                             bajaUrl: img.urls.baja, originalUrl: img.urls.original)
                        }
                        print("🖼️ syncImages - Iniciando descarga de \(imagesCopy.count) imágenes en background...")
                        Task {
                            await self.downloadImageData(from: imagesCopy, quality: quality)
                        }

                        self.updateMetadata(key: SyncMetadata.imagesKey, count: data.syncImages.count, ctx: ctx)
                        continuation.resume()

                    case .failure(let error):
                        print("❌ syncImages - Error de red: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    // MARK: - Private: Download Image Data

    private func downloadImageData(
        from images: [(entityId: String, entityType: String, bajaUrl: String?, originalUrl: String?)],
        quality: OfflineImageQuality
    ) async {
        guard let ctx = modelContext else { return }
        var downloaded = 0, failed = 0
        for img in images {
            let urlString: String?
            switch quality {
            case .baja: urlString = img.bajaUrl
            case .original: urlString = img.originalUrl
            }

            guard let urlStr = urlString, let url = URL(string: urlStr) else {
                failed += 1
                continue
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let imgId = "\(img.entityId)_\(img.entityType)"
                let descriptor = FetchDescriptor<LocalImage>(
                    predicate: #Predicate { $0.id == imgId }
                )
                if let localImg = try? ctx.fetch(descriptor).first {
                    switch quality {
                    case .baja: localImg.bajaData = data
                    case .original: localImg.originalData = data
                    }
                    try? ctx.save()
                    downloaded += 1
                }
            } catch {
                failed += 1
            }
        }
        print("🖼️ downloadImageData - Completado: \(downloaded) descargadas, \(failed) fallidas de \(images.count) totales")
    }

    // MARK: - Private: Build Embeddings

    private func buildEmbeddings() async {
        guard let ctx = modelContext else { return }

        let embeddingService = LocalEmbeddingService.shared
        embeddingProgress = 0.0

        let branches = (try? ctx.fetch(FetchDescriptor<LocalBranch>())) ?? []
        let products = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
        let total = Double(branches.count + products.count)
        guard total > 0 else {
            embeddingProgress = 1.0
            return
        }

        var indexed = 0.0

        for branch in branches {
            if branch.embeddingData == nil {
                branch.embedding = embeddingService.embed(text: branch.searchableText)
            }
            indexed += 1
            embeddingProgress = indexed / total
        }

        for product in products {
            if product.embeddingData == nil {
                product.embedding = embeddingService.embed(text: product.searchableText)
            }
            indexed += 1
            embeddingProgress = indexed / total
        }

        try? ctx.save()
        embeddingProgress = 1.0
    }

    // MARK: - Private: Metadata

    private func updateMetadata(key: String, count: Int, ctx: ModelContext) {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == key }
        )
        if let meta = try? ctx.fetch(descriptor).first {
            meta.lastSyncDate = Date()
            meta.recordCount = count
        } else {
            let meta = SyncMetadata(key: key)
            meta.lastSyncDate = Date()
            meta.recordCount = count
            ctx.insert(meta)
        }
        try? ctx.save()
    }

    // MARK: - Local Image Lookup

    func localImageData(for entityId: String, entityType: String, quality: OfflineImageQuality) -> Data? {
        guard let ctx = modelContext else { return nil }
        let imgId = "\(entityId)_\(entityType)"
        let descriptor = FetchDescriptor<LocalImage>(predicate: #Predicate { $0.id == imgId })
        guard let localImg = try? ctx.fetch(descriptor).first else { return nil }
        switch quality {
        case .baja: return localImg.bajaData
        case .original: return localImg.originalData
        }
    }

    /// Devuelve la URL a usar para una imagen: local si existe, S3 si no
    func imageUrl(for entityId: String, entityType: String, fallbackUrl: String?, quality: OfflineImageQuality) -> String? {
        guard let ctx = modelContext else { return fallbackUrl }
        let imgId = "\(entityId)_\(entityType)"
        let descriptor = FetchDescriptor<LocalImage>(predicate: #Predicate { $0.id == imgId })
        if let localImg = try? ctx.fetch(descriptor).first {
            // Si hay datos locales, se usan en otro lado; aquí devolvemos la URL sincronizada
            switch quality {
            case .baja: return localImg.bajaUrl ?? fallbackUrl
            case .original: return localImg.originalUrl ?? fallbackUrl
            }
        }
        return fallbackUrl
    }
}

// MARK: - Errors

enum OfflineError: LocalizedError {
    case noContext

    var errorDescription: String? {
        switch self {
        case .noContext: return "Base de datos local no disponible"
        }
    }
}
