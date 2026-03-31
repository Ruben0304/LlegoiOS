// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

public extension LlegoAPI {
  enum PaymentAttemptStatusEnum: String, EnumType {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case awaitingProof = "AWAITING_PROOF"
    case awaitingBusiness = "AWAITING_BUSINESS"
    case awaitingDelivery = "AWAITING_DELIVERY"
    case awaitingKyc = "AWAITING_KYC"
    case completed = "COMPLETED"
    case failed = "FAILED"
    case expired = "EXPIRED"
    case cancelled = "CANCELLED"
    case disputed = "DISPUTED"
    case refundRequested = "REFUND_REQUESTED"
    case refundProcessing = "REFUND_PROCESSING"
    case refunded = "REFUNDED"
  }

}