import Foundation

struct SearchCartContext: Sendable {
    let branchId: String
    let branchName: String
    let cartProductNames: [String]
    let productIds: Set<String>
}
