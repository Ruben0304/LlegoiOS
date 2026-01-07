import Foundation

// MARK: - Shared Store Models

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
}
