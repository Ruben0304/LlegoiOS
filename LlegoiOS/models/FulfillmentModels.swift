import Foundation

enum FulfillmentMode: String, Codable, CaseIterable {
    case delivery = "DELIVERY"
    case pickup = "PICKUP"
}

struct PickupSelection: Codable, Equatable {
    let branchId: String
    let branchName: String
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let scheduleJson: String?
    var selectedWindowId: String?
}

enum CheckoutIssueCode: String, Codable {
    case pickupNotEnabled = "PICKUP_NOT_ENABLED"
    case pickupNotAvailableForBranch = "PICKUP_NOT_AVAILABLE_FOR_BRANCH"
    case branchClosedForPickup = "BRANCH_CLOSED_FOR_PICKUP"
    case itemNotPickupEligible = "ITEM_NOT_PICKUP_ELIGIBLE"
    case pickupStockUnavailable = "PICKUP_STOCK_UNAVAILABLE"
    case fulfillmentPaymentMethodNotAllowed = "FULFILLMENT_PAYMENT_METHOD_NOT_ALLOWED"
    case checkoutRepriceRequired = "CHECKOUT_REPRICE_REQUIRED"
}

struct CheckoutValidationResultUI {
    let isValid: Bool
    let issues: [CheckoutIssueCode]
}

struct FulfillmentPayloadInput {
    let type: FulfillmentMode
    let pickupBranchId: String?
    let pickupWindowId: String?
}

extension FulfillmentPayloadInput {
    static let delivery = FulfillmentPayloadInput(
        type: .delivery,
        pickupBranchId: nil,
        pickupWindowId: nil
    )
}
