//
//  OfflineSyncService.swift
//  LlegoiOS
//
//  Servicio singleton que maneja la sincronización de datos locales
//  y descarga de imágenes desde el backend.
//
//  Sync incremental: cada tipo de entidad (negocios/sucursales, productos,
//  imágenes) guarda su propio cursor `serverSince` (SyncMetadata.serverSince).
//  Antes de cada sync se pide un `syncCheckpoint` con los IDs actualmente
//  activos en el servidor; se usa para podar localmente lo que ya no existe.
//

import Foundation
import SwiftData
import Apollo
import Combine
import UIKit

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

// MARK: - Sync Checkpoint

/// IDs activos en el servidor + marca de tiempo, usados para sync incremental
/// (como `since` en la próxima llamada) y para podar localmente lo eliminado.
private struct SyncCheckpointSnapshot {
    let businessIds: Set<String>
    let branchIds: Set<String>
    let productIds: Set<String>
    let syncedAt: String
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
            let checkpoint = try await fetchCheckpoint()

            // 1. Sync negocios y branches
            syncStatus = .syncing(.businesses)
            try await syncBusinesses(checkpoint: checkpoint)

            // 2. Sync productos
            syncStatus = .syncing(.products)
            try await syncProducts(checkpoint: checkpoint)

            // 3. Indexar embeddings (solo lo nuevo/modificado)
            syncStatus = .syncing(.embeddings)
            await buildEmbeddings()

            // 4. Imágenes (opcional)
            if downloadImages {
                syncStatus = .syncing(.images)
                try await syncImages(quality: imageQuality, checkpoint: checkpoint)
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
            let checkpoint = try await fetchCheckpoint()

            syncStatus = .syncing(.businesses)
            try await syncBusinesses(checkpoint: checkpoint)

            syncStatus = .syncing(.products)
            try await syncProducts(checkpoint: checkpoint)

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
            let checkpoint = try await fetchCheckpoint()
            syncStatus = .syncing(.images)
            try await syncImages(quality: quality, checkpoint: checkpoint)
            syncStatus = .done
            refreshStats()
            try await Task.sleep(nanoseconds: 2_000_000_000)
            syncStatus = .idle
        } catch {
            syncStatus = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private: Checkpoint

    /// Pide al servidor los IDs actualmente activos + su marca de tiempo.
    /// Se usa como `since` para el próximo sync incremental y para podar
    /// localmente negocios/sucursales/productos que ya no existen.
    private func fetchCheckpoint() async throws -> SyncCheckpointSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncCheckpointQuery(),
                cachePolicy: .fetchIgnoringCacheData
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    guard let data = graphQLResult.data else {
                        continuation.resume(throwing: OfflineError.noData)
                        return
                    }
                    let cp = data.syncCheckpoint
                    continuation.resume(returning: SyncCheckpointSnapshot(
                        businessIds: Set(cp.businessIds),
                        branchIds: Set(cp.branchIds),
                        productIds: Set(cp.productIds),
                        syncedAt: cp.syncedAt
                    ))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private: Sync Businesses

    private func syncBusinesses(checkpoint: SyncCheckpointSnapshot) async throws {
        print("🏪 syncBusinesses - Iniciando...")
        guard let ctx = modelContext else {
            print("❌ syncBusinesses - modelContext es nil")
            throw OfflineError.noContext
        }

        let since = loadCursor(key: SyncMetadata.businessesKey, ctx: ctx)

        return try await withCheckedThrowingContinuation { continuation in
            print("🏪 syncBusinesses - Lanzando query Apollo (since: \(since ?? "nil"))...")
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncBusinessesWithBranchesQuery(since: since.map { .some($0) } ?? .none),
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

                        print("🏪 syncBusinesses - Respuesta recibida: \(data.syncBusinessesWithBranches.count) negocios (delta desde el último sync)")

                        do {
                            for biz in data.syncBusinessesWithBranches {
                                let localBiz = self.upsertBusiness(from: biz, ctx: ctx)
                                for branch in biz.branches {
                                    self.upsertBranch(from: branch, business: localBiz, ctx: ctx)
                                }
                            }
                            try ctx.save()

                            // Eliminar negocios/sucursales que ya no existen en el servidor
                            self.pruneRemovedBusinessesAndBranches(checkpoint: checkpoint, ctx: ctx)

                            let totalBusinesses = (try? ctx.fetch(FetchDescriptor<LocalBusiness>()))?.count ?? 0
                            let totalBranches = (try? ctx.fetch(FetchDescriptor<LocalBranch>()))?.count ?? 0
                            self.updateMetadata(key: SyncMetadata.businessesKey, count: totalBusinesses, serverSince: checkpoint.syncedAt, ctx: ctx)

                            print("💾 syncBusinesses - Guardado OK. En BD: \(totalBusinesses) negocios, \(totalBranches) sucursales")
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

    private func upsertBusiness(
        from biz: LlegoAPI.SyncBusinessesWithBranchesQuery.Data.SyncBusinessesWithBranch,
        ctx: ModelContext
    ) -> LocalBusiness {
        let bizId = biz.id
        let descriptor = FetchDescriptor<LocalBusiness>(predicate: #Predicate { $0.id == bizId })

        if let existing = (try? ctx.fetch(descriptor))?.first {
            existing.name = biz.name
            existing.globalRating = biz.globalRating
            existing.avatar = biz.avatar
            existing.avatarUrl = biz.avatarUrl
            existing.businessDescription = biz.description
            existing.tags = biz.tags ?? []
            existing.isActive = biz.isActive
            existing.createdAt = "\(biz.createdAt)"
            return existing
        }

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
        return localBiz
    }

    private func upsertBranch(
        from branch: LlegoAPI.SyncBusinessesWithBranchesQuery.Data.SyncBusinessesWithBranch.Branch,
        business: LocalBusiness,
        ctx: ModelContext
    ) {
        let branchId = branch.id
        let lat = branch.coordinates.coordinates.count > 1 ? branch.coordinates.coordinates[1] : 0.0
        let lon = branch.coordinates.coordinates.count > 0 ? branch.coordinates.coordinates[0] : 0.0
        let descriptor = FetchDescriptor<LocalBranch>(predicate: #Predicate { $0.id == branchId })

        if let existing = (try? ctx.fetch(descriptor))?.first {
            // Solo se invalida el embedding si cambió algo que afecta al texto indexable
            let searchableTextChanged = existing.name != branch.name
                || existing.tipos != branch.tipos
                || existing.address != branch.address

            existing.businessId = branch.businessId
            existing.name = branch.name
            existing.address = branch.address
            existing.latitude = lat
            existing.longitude = lon
            existing.phone = branch.phone
            existing.isActive = branch.isActive
            existing.status = branch.status
            existing.avatar = branch.avatar
            existing.avatarUrl = branch.avatarUrl
            existing.coverImage = branch.coverImage
            existing.coverUrl = branch.coverUrl
            existing.tipos = branch.tipos
            existing.deliveryRadius = branch.deliveryRadius
            existing.createdAt = "\(branch.createdAt)"
            existing.business = business

            if searchableTextChanged {
                existing.embeddingData = nil
            }
            return
        }

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
        localBranch.business = business
        ctx.insert(localBranch)
    }

    private func pruneRemovedBusinessesAndBranches(checkpoint: SyncCheckpointSnapshot, ctx: ModelContext) {
        let allBusinesses = (try? ctx.fetch(FetchDescriptor<LocalBusiness>())) ?? []
        for biz in allBusinesses where !checkpoint.businessIds.contains(biz.id) {
            ctx.delete(biz)  // cascada: borra también sus LocalBranch (deleteRule: .cascade)
        }

        let allBranches = (try? ctx.fetch(FetchDescriptor<LocalBranch>())) ?? []
        for branch in allBranches where !checkpoint.branchIds.contains(branch.id) {
            ctx.delete(branch)
        }

        try? ctx.save()
    }

    // MARK: - Private: Sync Products

    private func syncProducts(checkpoint: SyncCheckpointSnapshot) async throws {
        guard let ctx = modelContext else { throw OfflineError.noContext }

        let since = loadCursor(key: SyncMetadata.productsKey, ctx: ctx)

        return try await withCheckedThrowingContinuation { continuation in
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncProductsQuery(
                    availableOnly: .some(true),
                    since: since.map { .some($0) } ?? .none
                ),
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

                        print("📦 syncProducts - Respuesta recibida: \(data.syncProducts.count) productos (delta desde el último sync)")

                        do {
                            for p in data.syncProducts {
                                self.upsertProduct(from: p, ctx: ctx)
                            }
                            try ctx.save()

                            // Eliminar productos que ya no existen/dejaron de estar disponibles
                            self.pruneRemovedProducts(checkpoint: checkpoint, ctx: ctx)

                            let totalProducts = (try? ctx.fetch(FetchDescriptor<LocalProduct>()))?.count ?? 0
                            self.updateMetadata(key: SyncMetadata.productsKey, count: totalProducts, serverSince: checkpoint.syncedAt, ctx: ctx)

                            print("💾 syncProducts - Guardado OK. En BD: \(totalProducts) productos")
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

    private func upsertProduct(from p: LlegoAPI.SyncProductsQuery.Data.SyncProduct, ctx: ModelContext) {
        let productId = p.id
        let descriptor = FetchDescriptor<LocalProduct>(predicate: #Predicate { $0.id == productId })

        if let existing = (try? ctx.fetch(descriptor))?.first {
            let searchableTextChanged = existing.name != p.name || existing.productDescription != p.description

            existing.branchId = p.branchId
            existing.name = p.name
            existing.productDescription = p.description
            existing.weight = p.weight
            existing.price = p.price
            existing.currency = p.currency
            existing.image = p.image
            existing.imageUrl = p.imageUrl
            existing.availability = p.availability
            existing.categoryId = p.categoryId
            existing.createdAt = "\(p.createdAt)"

            if searchableTextChanged {
                existing.embeddingData = nil
            }
            return
        }

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

    private func pruneRemovedProducts(checkpoint: SyncCheckpointSnapshot, ctx: ModelContext) {
        let allProducts = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
        for product in allProducts where !checkpoint.productIds.contains(product.id) {
            ctx.delete(product)
        }
        try? ctx.save()
    }

    // MARK: - Private: Sync Images

    private func syncImages(quality: OfflineImageQuality, checkpoint: SyncCheckpointSnapshot) async throws {
        print("🖼️ syncImages - Iniciando (calidad: \(quality.rawValue))...")
        guard let ctx = modelContext else {
            print("❌ syncImages - modelContext es nil")
            throw OfflineError.noContext
        }

        let since = loadCursor(key: SyncMetadata.imagesKey, ctx: ctx)

        let qualities: GraphQLNullable<[GraphQLEnum<LlegoAPI.ImageQuality>]>
        switch quality {
        case .baja:
            qualities = .some([.init(.baja)])
        case .original:
            qualities = .some([.init(.original)])
        }

        return try await withCheckedThrowingContinuation { continuation in
            print("🖼️ syncImages - Lanzando query Apollo (since: \(since ?? "nil"))...")
            apolloClient.fetchCompat(
                query: LlegoAPI.SyncImagesQuery(
                    entityType: .none,
                    entityIds: .none,
                    qualities: qualities,
                    since: since.map { .some($0) } ?? .none
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

                        print("🖼️ syncImages - \(data.syncImages.count) imágenes recibidas (delta desde el último sync)")

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

                        // Limpiar imágenes de negocios/sucursales/productos que ya no existen
                        self.pruneOrphanedImages(checkpoint: checkpoint, ctx: ctx)

                        // Descargar los datos de imagen en background
                        let imagesCopy = data.syncImages.map { img in
                            (entityId: img.entityId, entityType: img.entityType,
                             bajaUrl: img.urls.baja, originalUrl: img.urls.original)
                        }
                        print("🖼️ syncImages - Iniciando descarga de \(imagesCopy.count) imágenes en background...")
                        Task {
                            await self.downloadImageData(from: imagesCopy, quality: quality)
                        }

                        let totalImages = (try? ctx.fetch(FetchDescriptor<LocalImage>()))?.count ?? 0
                        self.updateMetadata(key: SyncMetadata.imagesKey, count: totalImages, serverSince: checkpoint.syncedAt, ctx: ctx)
                        continuation.resume()

                    case .failure(let error):
                        print("❌ syncImages - Error de red: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    private func pruneOrphanedImages(checkpoint: SyncCheckpointSnapshot, ctx: ModelContext) {
        let allImages = (try? ctx.fetch(FetchDescriptor<LocalImage>())) ?? []
        for img in allImages {
            let stillExists: Bool
            switch img.entityType {
            case "business": stillExists = checkpoint.businessIds.contains(img.entityId)
            case "branch": stillExists = checkpoint.branchIds.contains(img.entityId)
            case "product": stillExists = checkpoint.productIds.contains(img.entityId)
            default: stillExists = false
            }
            if !stillExists {
                ctx.delete(img)
            }
        }
        try? ctx.save()
    }

    // MARK: - Private: Download Image Data

    private func downloadImageData(
        from images: [(entityId: String, entityType: String, bajaUrl: String?, originalUrl: String?)],
        quality: OfflineImageQuality
    ) async {
        guard let ctx = modelContext else { return }
        var downloaded = 0, skipped = 0, failed = 0

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

            let imgId = "\(img.entityId)_\(img.entityType)"
            let descriptor = FetchDescriptor<LocalImage>(
                predicate: #Predicate { $0.id == imgId }
            )
            guard let localImg = try? ctx.fetch(descriptor).first else {
                failed += 1
                continue
            }

            let alreadyLocal: Bool
            switch quality {
            case .baja: alreadyLocal = localImg.hasBajaLocal
            case .original: alreadyLocal = localImg.hasOriginalLocal
            }
            if alreadyLocal {
                skipped += 1
                continue
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                switch quality {
                case .baja: localImg.bajaData = data
                case .original: localImg.originalData = data
                }
                try? ctx.save()
                // Volcar al caché de imágenes bajo su URL para que las pantallas
                // (CachedAsyncImage) puedan mostrarla sin conexión.
                primeImageCache(url: urlStr, data: data)
                downloaded += 1
            } catch {
                failed += 1
            }
        }
        print("🖼️ downloadImageData - Completado: \(downloaded) descargadas, \(skipped) omitidas (ya locales), \(failed) fallidas de \(images.count) totales")
    }

    /// Guarda los bytes ya descargados en el caché de imágenes usando la URL
    /// como clave (la misma que usa `CachedAsyncImage`).
    private nonisolated func primeImageCache(url: String, data: Data) {
        DispatchQueue.global(qos: .utility).async {
            guard let image = UIImage(data: data) else { return }
            ImageCacheManager.shared.setImage(image, for: url)
        }
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

        // Cede el hilo principal periódicamente para no congelar la UI durante sync grandes.
        let yieldEvery = 25
        var indexed = 0.0

        for (i, branch) in branches.enumerated() {
            if branch.embeddingData == nil {
                branch.embedding = embeddingService.embed(text: branch.searchableText)
            }
            indexed += 1
            embeddingProgress = indexed / total
            if i % yieldEvery == 0 {
                try? ctx.save()
                await Task.yield()
            }
        }

        for (i, product) in products.enumerated() {
            if product.embeddingData == nil {
                product.embedding = embeddingService.embed(text: product.searchableText)
            }
            indexed += 1
            embeddingProgress = indexed / total
            if i % yieldEvery == 0 {
                try? ctx.save()
                await Task.yield()
            }
        }

        try? ctx.save()
        embeddingProgress = 1.0
    }

    // MARK: - Private: Metadata

    private func updateMetadata(key: String, count: Int, serverSince: String? = nil, ctx: ModelContext) {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == key }
        )
        if let meta = try? ctx.fetch(descriptor).first {
            meta.lastSyncDate = Date()
            meta.recordCount = count
            if let serverSince {
                meta.serverSince = serverSince
            }
        } else {
            let meta = SyncMetadata(key: key)
            meta.lastSyncDate = Date()
            meta.recordCount = count
            meta.serverSince = serverSince
            ctx.insert(meta)
        }
        try? ctx.save()
    }

    private func loadCursor(key: String, ctx: ModelContext) -> String? {
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == key }
        )
        return (try? ctx.fetch(descriptor))?.first?.serverSince
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
    case noData

    var errorDescription: String? {
        switch self {
        case .noContext: return "Base de datos local no disponible"
        case .noData: return "El servidor no devolvió datos de sincronización"
        }
    }
}
