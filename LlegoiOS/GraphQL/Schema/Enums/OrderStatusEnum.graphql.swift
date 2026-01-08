// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

public extension LlegoAPI {
  enum OrderStatusEnum: String, EnumType {
    case pendingAcceptance = "PENDING_ACCEPTANCE"
    case modifiedByStore = "MODIFIED_BY_STORE"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case readyForPickup = "READY_FOR_PICKUP"
    case onTheWay = "ON_THE_WAY"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
  }

}