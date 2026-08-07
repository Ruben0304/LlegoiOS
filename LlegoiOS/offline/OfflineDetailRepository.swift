//
//  OfflineDetailRepository.swift
//  LlegoiOS
//
//  Lee los detalles de producto y de sucursal desde los datos sincronizados
//  (SwiftData) para que las pantallas de detalle funcionen sin conexión.
//
//  Complementa a LocalSearchRepository: aquel resuelve la búsqueda, este
//  resuelve "entrar" a un resultado (producto o sucursal) y sus secciones
//  relacionadas (productos de la tienda, similares, sucursales hermanas).
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class OfflineDetailRepository {
    static let shared = OfflineDetailRepository()

    private var modelContext: ModelContext?

    /// URLs ya volcadas al caché de imágenes en esta sesión, para no decodificar
    /// dos veces los mismos datos.
    private var primedImageKeys: Set<String> = []

    private init() {}

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var isAvailable: Bool { modelContext != nil }

    // MARK: - Producto

    func productDetail(id: String) -> ProductDetailGraphQL? {
        guard let ctx = modelContext, let p = fetchProduct(id: id, ctx: ctx) else { return nil }

        let branch = fetchBranch(id: p.branchId, ctx: ctx)
        let productImage = offlineImageURL(entityId: p.id, entityType: "product", fallback: p.imageUrl) ?? p.imageUrl
        let branchLogo = branch.flatMap {
            offlineImageURL(entityId: $0.id, entityType: "branch", fallback: $0.avatarUrl)
        }

        return ProductDetailGraphQL(
            id: p.id,
            branchId: p.branchId,
            name: p.name,
            description: p.productDescription,
            weight: p.weight,
            price: p.price,
            currency: p.currency,
            convertedPrice: nil,
            convertedCurrency: nil,
            exchangeRate: nil,
            imageUrl: productImage,
            availability: p.availability,
            categoryId: p.categoryId,
            createdAt: p.createdAt,
            businessName: branch?.name ?? branch?.business?.name ?? "Tienda",
            businessLogoUrl: branchLogo,
            shopRating: branch?.business?.globalRating,
            variantListIds: nil,
            variantLists: nil
        )
    }

    /// Productos similares offline: misma categoría (o misma sucursal si el
    /// producto no tiene categoría), ordenados priorizando la misma sucursal.
    func similarProducts(productId: String, limit: Int = 7) -> [Product] {
        guard let ctx = modelContext, let base = fetchProduct(id: productId, ctx: ctx) else { return [] }

        let all = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
        let branchNames = branchNameMap(ctx: ctx)

        let candidates = all.filter { candidate in
            guard candidate.id != base.id, candidate.availability else { return false }
            if let categoryId = base.categoryId, !categoryId.isEmpty {
                return candidate.categoryId == categoryId
            }
            return candidate.branchId == base.branchId
        }
        .sorted { lhs, rhs in
            // Primero los de la misma sucursal, luego el resto por fecha
            let lhsSame = lhs.branchId == base.branchId
            let rhsSame = rhs.branchId == base.branchId
            if lhsSame != rhsSame { return lhsSame }
            return lhs.createdAt > rhs.createdAt
        }
        .prefix(limit)

        return candidates.map { p in
            Product(
                id: p.id,
                name: p.name,
                shop: branchNames[p.branchId] ?? "",
                shopLogoUrl: "",
                weight: p.weight,
                price: p.formattedPrice,
                imageUrl: offlineImageURL(entityId: p.id, entityType: "product", fallback: p.imageUrl) ?? p.imageUrl
            )
        }
    }

    /// Sucursales que venden productos de la misma categoría que `productId`.
    func branchesForProduct(productId: String, limit: Int = 6) -> [BranchGraphQL] {
        guard let ctx = modelContext, let base = fetchProduct(id: productId, ctx: ctx) else { return [] }

        let all = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
        var branchIds: [String] = []
        for p in all where p.id != base.id && p.availability {
            guard p.branchId != base.branchId else { continue }
            if let categoryId = base.categoryId, !categoryId.isEmpty {
                guard p.categoryId == categoryId else { continue }
            }
            if !branchIds.contains(p.branchId) {
                branchIds.append(p.branchId)
            }
            if branchIds.count >= limit { break }
        }

        return branchIds.compactMap { id in
            fetchBranch(id: id, ctx: ctx).map { mapToBranchGraphQL($0, ctx: ctx) }
        }
    }

    /// Productos descargados, opcionalmente filtrados por sucursal y categoría.
    /// Se usa para que la lista de productos de una tienda funcione sin conexión.
    func products(branchId: String?, categoryId: String?, limit: Int = 100) -> [ProductGraphQL] {
        guard let ctx = modelContext else { return [] }

        var descriptor = FetchDescriptor<LocalProduct>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let branchId {
            descriptor.predicate = #Predicate { $0.branchId == branchId }
        }

        var products = (try? ctx.fetch(descriptor)) ?? []
        if let categoryId, !categoryId.isEmpty, categoryId != "all" {
            products = products.filter { $0.categoryId == categoryId }
        }

        let branchNames = branchNameMap(ctx: ctx)

        return products.prefix(limit).map { p in
            ProductGraphQL(
                id: p.id,
                branchId: p.branchId,
                name: p.name,
                price: p.price,
                currency: p.currency,
                imageUrl: offlineImageURL(entityId: p.id, entityType: "product", fallback: p.imageUrl) ?? p.imageUrl,
                availability: p.availability,
                createdAt: p.createdAt,
                businessName: branchNames[p.branchId] ?? "Tienda",
                businessLogoUrl: "",
                distanceKm: nil,
                categoryId: p.categoryId,
                categoryName: nil
            )
        }
    }

    // MARK: - Sucursal

    func branchDetail(id: String) -> BranchDetailGraphQL? {
        guard let ctx = modelContext, let branch = fetchBranch(id: id, ctx: ctx) else { return nil }

        let avatar = offlineImageURL(entityId: branch.id, entityType: "branch", fallback: branch.avatarUrl)
        let cover = offlineImageURL(entityId: branch.id, entityType: "branch", fallback: branch.coverUrl)

        return BranchDetailGraphQL(
            id: branch.id,
            businessId: branch.businessId,
            name: branch.name,
            address: branch.address,
            coordinates: CoordinatesGraphQL(
                type: "Point",
                coordinates: [branch.longitude, branch.latitude]
            ),
            phone: branch.phone,
            status: branch.status ?? "",
            avatarUrl: avatar,
            avatarUrlBaja: avatar,
            avatarUrlAlta: avatar,
            coverUrl: cover,
            coverUrlBaja: cover,
            coverUrlAlta: cover,
            deliveryRadius: branch.deliveryRadius,
            facilities: branch.tipos,
            createdAt: branch.createdAt,
            socialMedia: nil,
            acceptedCurrency: nil,
            exchangeRate: nil,
            schedule: nil,
            showcases: [],
            catalogOnly: false
        )
    }

    func businessDetail(id: String) -> BusinessDetailGraphQL? {
        guard let ctx = modelContext else { return nil }
        let descriptor = FetchDescriptor<LocalBusiness>(predicate: #Predicate { $0.id == id })
        guard let biz = (try? ctx.fetch(descriptor))?.first else { return nil }

        let avatar = offlineImageURL(entityId: biz.id, entityType: "business", fallback: biz.avatarUrl)
        return BusinessDetailGraphQL(
            id: biz.id,
            name: biz.name,
            socialMedia: nil,
            avatarUrl: avatar,
            avatarUrlBaja: avatar,
            avatarUrlAlta: avatar,
            coverUrl: nil
        )
    }

    /// Otras sucursales del mismo negocio (excluyendo la actual).
    func siblingBranches(businessId: String, excluding branchId: String) -> [BranchGraphQL] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<LocalBranch>(
            predicate: #Predicate { $0.businessId == businessId && $0.isActive == true }
        )
        let branches = (try? ctx.fetch(descriptor)) ?? []
        return branches
            .filter { $0.id != branchId }
            .map { mapToBranchGraphQL($0, ctx: ctx) }
    }

    /// Sucursales "similares": comparten al menos un tipo con la sucursal dada.
    func similarBranches(branchId: String, limit: Int = 6) -> [BranchGraphQL] {
        guard let ctx = modelContext, let base = fetchBranch(id: branchId, ctx: ctx) else { return [] }

        let all = (try? ctx.fetch(FetchDescriptor<LocalBranch>())) ?? []
        let baseTipos = Set(base.tipos)

        return all
            .filter { candidate in
                guard candidate.id != base.id, candidate.isActive else { return false }
                if baseTipos.isEmpty { return true }
                return !baseTipos.isDisjoint(with: Set(candidate.tipos))
            }
            .prefix(limit)
            .map { mapToBranchGraphQL($0, ctx: ctx) }
    }

    func branchProducts(branchId: String, limit: Int = 10) -> [StoreProductGraphQL] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<LocalProduct>(
            predicate: #Predicate { $0.branchId == branchId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let products = (try? ctx.fetch(descriptor)) ?? []
        return products.prefix(limit).map { p in
            StoreProductGraphQL(
                id: p.id,
                branchId: p.branchId,
                name: p.name,
                price: p.price,
                currency: p.currency,
                imageUrl: offlineImageURL(entityId: p.id, entityType: "product", fallback: p.imageUrl) ?? p.imageUrl,
                availability: p.availability,
                createdAt: p.createdAt
            )
        }
    }

    // MARK: - Helpers de fetch

    private func fetchProduct(id: String, ctx: ModelContext) -> LocalProduct? {
        let descriptor = FetchDescriptor<LocalProduct>(predicate: #Predicate { $0.id == id })
        return (try? ctx.fetch(descriptor))?.first
    }

    private func fetchBranch(id: String, ctx: ModelContext) -> LocalBranch? {
        let descriptor = FetchDescriptor<LocalBranch>(predicate: #Predicate { $0.id == id })
        return (try? ctx.fetch(descriptor))?.first
    }

    private func branchNameMap(ctx: ModelContext) -> [String: String] {
        let branches = (try? ctx.fetch(FetchDescriptor<LocalBranch>())) ?? []
        return Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
    }

    private func mapToBranchGraphQL(_ branch: LocalBranch, ctx: ModelContext) -> BranchGraphQL {
        let avatar = offlineImageURL(entityId: branch.id, entityType: "branch", fallback: branch.avatarUrl)
        let cover = offlineImageURL(entityId: branch.id, entityType: "branch", fallback: branch.coverUrl)

        let branchId = branch.id
        let descriptor = FetchDescriptor<LocalProduct>(
            predicate: #Predicate { $0.branchId == branchId }
        )
        let products = ((try? ctx.fetch(descriptor)) ?? []).prefix(4).map { p in
            BranchProductGraphQL(
                id: p.id,
                name: p.name,
                price: p.price,
                currency: p.currency,
                imageUrl: offlineImageURL(entityId: p.id, entityType: "product", fallback: p.imageUrl) ?? p.imageUrl
            )
        }

        return BranchGraphQL(
            id: branch.id,
            businessId: branch.businessId,
            name: branch.name,
            description: nil,
            address: branch.address ?? "",
            coordinates: CoordinatesGraphQL(
                type: "Point",
                coordinates: [branch.longitude, branch.latitude]
            ),
            phone: branch.phone,
            status: branch.status ?? "",
            avatarUrl: avatar,
            avatarUrlBaja: avatar,
            avatarUrlAlta: avatar,
            coverUrl: cover,
            coverUrlBaja: cover,
            coverUrlAlta: cover,
            deliveryRadius: branch.deliveryRadius,
            facilities: branch.tipos,
            createdAt: branch.createdAt,
            schedule: nil,
            products: Array(products),
            catalogOnly: false
        )
    }

    // MARK: - Imágenes

    /// Devuelve la URL a mostrar y, si hay bytes descargados para esa entidad,
    /// los vuelca al caché de imágenes bajo esa misma clave para que
    /// `CachedAsyncImage` los encuentre sin red.
    private func offlineImageURL(entityId: String, entityType: String, fallback: String?) -> String? {
        guard let ctx = modelContext else { return fallback }

        let imgId = "\(entityId)_\(entityType)"
        let descriptor = FetchDescriptor<LocalImage>(predicate: #Predicate { $0.id == imgId })
        guard let localImg = (try? ctx.fetch(descriptor))?.first else { return fallback }

        // Preferir la URL cuyos bytes están descargados; si no hay bytes, la que exista.
        let url: String?
        let data: Data?
        if let originalData = localImg.originalData, let originalUrl = localImg.originalUrl {
            url = originalUrl
            data = originalData
        } else if let bajaData = localImg.bajaData, let bajaUrl = localImg.bajaUrl {
            url = bajaUrl
            data = bajaData
        } else {
            url = localImg.originalUrl ?? localImg.bajaUrl
            data = nil
        }

        let finalUrl = (url?.isEmpty == false ? url : nil) ?? fallback
        if let data, let finalUrl {
            primeImageCache(url: finalUrl, data: data)
        }
        return finalUrl
    }

    private func primeImageCache(url: String, data: Data) {
        guard !primedImageKeys.contains(url) else { return }
        primedImageKeys.insert(url)

        // Si ya está en memoria no hace falta decodificar de nuevo.
        if ImageCacheManager.shared.getMemoryImage(for: url) != nil { return }

        DispatchQueue.global(qos: .utility).async {
            guard let image = UIImage(data: data) else { return }
            ImageCacheManager.shared.setImage(image, for: url)
        }
    }
}
