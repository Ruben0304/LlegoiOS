import SwiftUI

// MARK: - Store Model (UI compatibility layer)
struct Store: Identifiable {
    let id: String
    let name: String
    let etaMinutes: Int
    let logoUrl: String
    let bannerUrl: String
    let address: String?
    let rating: Double?

    init(id: String, name: String, etaMinutes: Int, logoUrl: String, bannerUrl: String, address: String? = nil, rating: Double? = nil) {
        self.id = id
        self.name = name
        self.etaMinutes = etaMinutes
        self.logoUrl = logoUrl
        self.bannerUrl = bannerUrl
        self.address = address
        self.rating = rating
    }

    // Convenience initializer for backward compatibility with default values
    init(id: String, name: String, address: String, etaMinutes: Int = 30, logoUrl: String = "", bannerUrl: String = "", rating: Double? = nil) {
        self.id = id
        self.name = name
        self.etaMinutes = etaMinutes
        self.logoUrl = logoUrl
        self.bannerUrl = bannerUrl
        self.address = address
        self.rating = rating
    }
}

// MARK: - Store Card Size
enum StoreCardSize {
    case medium
    case expanded
}

// MARK: - GraphQL Store Models

// Model to represent GraphQL Coordinates
struct CoordinatesGraphQL: Sendable {
    let type: String
    let coordinates: [Double]

    var latitude: Double {
        coordinates.count > 1 ? coordinates[1] : 0
    }

    var longitude: Double {
        coordinates.count > 0 ? coordinates[0] : 0
    }
}

// Model to represent GraphQL Branch (simplified, for lists)
struct BranchGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let avatarUrl: String?
    let coverUrl: String?
    let deliveryRadius: Double?
    let facilities: [String]?
    let createdAt: String
    let products: [BranchProductGraphQL]  // Productos anidados (opcional, puede estar vacío)
    
    init(id: String, businessId: String, name: String, address: String, coordinates: CoordinatesGraphQL, phone: String, status: String, avatarUrl: String?, coverUrl: String?, deliveryRadius: Double?, facilities: [String]?, createdAt: String, products: [BranchProductGraphQL] = []) {
        self.id = id
        self.businessId = businessId
        self.name = name
        self.address = address
        self.coordinates = coordinates
        self.phone = phone
        self.status = status
        self.avatarUrl = avatarUrl
        self.coverUrl = coverUrl
        self.deliveryRadius = deliveryRadius
        self.facilities = facilities
        self.createdAt = createdAt
        self.products = products
    }
}

// Model to represent a product nested in a branch (lightweight)
struct BranchProductGraphQL: Identifiable, Sendable {
    let id: String
    let name: String
    let price: Double
    let currency: String
    let imageUrl: String
}

// MARK: - Story Models
struct StoryData: Identifiable {
    let id: String
    let store: Store
    let items: [StoryItem]
    var currentIndex: Int = 0
    var isViewed: Bool = false
    var isLiked: Bool = false

    mutating func nextItem() -> Bool {
        if currentIndex < items.count - 1 {
            currentIndex += 1
            return true
        }
        return false
    }

    mutating func previousItem() -> Bool {
        if currentIndex > 0 {
            currentIndex -= 1
            return true
        }
        return false
    }

    var currentItem: StoryItem {
        items[currentIndex]
    }
}

struct StoryItem: Identifiable {
    let id: String
    let mediaUrl: String
    let mediaType: StoryMediaType
    let duration: TimeInterval // En segundos
    let timestamp: Date

    init(id: String = UUID().uuidString, mediaUrl: String, mediaType: StoryMediaType, duration: TimeInterval = 5.0, timestamp: Date = Date()) {
        self.id = id
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.duration = duration
        self.timestamp = timestamp
    }
}

enum StoryMediaType {
    case image
    case video
}

