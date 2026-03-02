//
//  OfflineModels.swift
//  LlegoiOS
//
//  Modelos SwiftData para persistencia local de datos de sincronización
//

import Foundation
import SwiftData

// MARK: - LocalBusiness

@Model
final class LocalBusiness {
    @Attribute(.unique) var id: String
    var name: String
    var globalRating: Double
    var avatar: String?
    var avatarUrl: String?
    var businessDescription: String?
    var tags: [String]
    var isActive: Bool
    var createdAt: String

    @Relationship(deleteRule: .cascade)
    var branches: [LocalBranch]

    init(
        id: String,
        name: String,
        globalRating: Double,
        avatar: String?,
        avatarUrl: String?,
        businessDescription: String?,
        tags: [String],
        isActive: Bool,
        createdAt: String
    ) {
        self.id = id
        self.name = name
        self.globalRating = globalRating
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.businessDescription = businessDescription
        self.tags = tags
        self.isActive = isActive
        self.createdAt = createdAt
        self.branches = []
    }
}

// MARK: - LocalBranch

@Model
final class LocalBranch {
    @Attribute(.unique) var id: String
    var businessId: String
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var phone: String
    var isActive: Bool
    var status: String?
    var avatar: String?
    var avatarUrl: String?
    var coverImage: String?
    var coverUrl: String?
    var tipos: [String]
    var deliveryRadius: Double?
    var createdAt: String

    // Embedding para búsqueda vectorial
    var embeddingData: Data?

    var business: LocalBusiness?

    init(
        id: String,
        businessId: String,
        name: String,
        address: String?,
        latitude: Double,
        longitude: Double,
        phone: String,
        isActive: Bool,
        status: String?,
        avatar: String?,
        avatarUrl: String?,
        coverImage: String?,
        coverUrl: String?,
        tipos: [String],
        deliveryRadius: Double?,
        createdAt: String
    ) {
        self.id = id
        self.businessId = businessId
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phone = phone
        self.isActive = isActive
        self.status = status
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.coverImage = coverImage
        self.coverUrl = coverUrl
        self.tipos = tipos
        self.deliveryRadius = deliveryRadius
        self.createdAt = createdAt
    }

    /// Texto indexable para embeddings.
    /// El nombre se repite 3 veces para darle más peso semántico
    /// frente a la dirección y los tipos.
    var searchableText: String {
        var parts: [String] = [name, name, name]
        if !tipos.isEmpty { parts.append(tipos.joined(separator: " ")) }
        if let addr = address { parts.append(addr) }
        return parts.joined(separator: " ")
    }

    var embedding: [Double]? {
        get {
            guard let data = embeddingData else { return nil }
            return try? JSONDecoder().decode([Double].self, from: data)
        }
        set {
            embeddingData = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - LocalProduct

@Model
final class LocalProduct {
    @Attribute(.unique) var id: String
    var branchId: String
    var name: String
    var productDescription: String
    var weight: String
    var price: Double
    var currency: String
    var image: String
    var imageUrl: String
    var availability: Bool
    var categoryId: String?
    var createdAt: String

    // Embedding para búsqueda vectorial
    var embeddingData: Data?

    init(
        id: String,
        branchId: String,
        name: String,
        productDescription: String,
        weight: String,
        price: Double,
        currency: String,
        image: String,
        imageUrl: String,
        availability: Bool,
        categoryId: String?,
        createdAt: String
    ) {
        self.id = id
        self.branchId = branchId
        self.name = name
        self.productDescription = productDescription
        self.weight = weight
        self.price = price
        self.currency = currency
        self.image = image
        self.imageUrl = imageUrl
        self.availability = availability
        self.categoryId = categoryId
        self.createdAt = createdAt
    }

    /// Texto indexable para embeddings: nombre (con peso) + descripción truncada.
    var searchableText: String {
        let shortDesc = productDescription.count > 80
            ? String(productDescription.prefix(80))
            : productDescription
        return "\(name) \(name) \(name) \(shortDesc)"
    }

    var embedding: [Double]? {
        get {
            guard let data = embeddingData else { return nil }
            return try? JSONDecoder().decode([Double].self, from: data)
        }
        set {
            embeddingData = try? JSONEncoder().encode(newValue)
        }
    }

    var formattedPrice: String {
        String(format: "%.2f %@", price, currency)
    }
}

// MARK: - LocalImage

@Model
final class LocalImage {
    @Attribute(.unique) var id: String  // entityId + "_" + entityType
    var entityId: String
    var entityType: String  // "business", "branch", "product"
    var imagePath: String

    // URLs remotas (para usar si no hay datos locales)
    var bajaUrl: String?
    var originalUrl: String?

    // Datos de imagen descargados localmente
    var bajaData: Data?
    var originalData: Data?

    init(
        entityId: String,
        entityType: String,
        imagePath: String,
        bajaUrl: String?,
        originalUrl: String?
    ) {
        self.id = "\(entityId)_\(entityType)"
        self.entityId = entityId
        self.entityType = entityType
        self.imagePath = imagePath
        self.bajaUrl = bajaUrl
        self.originalUrl = originalUrl
    }

    var hasBajaLocal: Bool { bajaData != nil }
    var hasOriginalLocal: Bool { originalData != nil }
}

// MARK: - SyncMetadata

@Model
final class SyncMetadata {
    @Attribute(.unique) var key: String
    var lastSyncDate: Date?
    var recordCount: Int

    init(key: String) {
        self.key = key
        self.lastSyncDate = nil
        self.recordCount = 0
    }

    static let businessesKey = "businesses"
    static let productsKey = "products"
    static let imagesKey = "images"
}
