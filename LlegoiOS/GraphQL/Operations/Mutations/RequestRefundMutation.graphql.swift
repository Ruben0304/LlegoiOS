// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RequestRefundMutation: GraphQLMutation {
    public static let operationName: String = "RequestRefund"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RequestRefund($paymentAttemptId: String!, $reason: String!, $jwt: String!) { requestRefund(paymentAttemptId: $paymentAttemptId, reason: $reason, jwt: $jwt) { __typename id status refundRequestedAt refundReason refundedAt refundAmount } }"#
      ))

    public var paymentAttemptId: String
    public var reason: String
    public var jwt: String

    public init(
      paymentAttemptId: String,
      reason: String,
      jwt: String
    ) {
      self.paymentAttemptId = paymentAttemptId
      self.reason = reason
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "paymentAttemptId": paymentAttemptId,
      "reason": reason,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("requestRefund", RequestRefund.self, arguments: [
          "paymentAttemptId": .variable("paymentAttemptId"),
          "reason": .variable("reason"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RequestRefundMutation.Data.self
      ] }

      /// Solicitar reembolso de un pago
      public var requestRefund: RequestRefund { __data["requestRefund"] }

      /// RequestRefund
      ///
      /// Parent Type: `PaymentAttemptType`
      public struct RequestRefund: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentAttemptType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("status", GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum>.self),
          .field("refundRequestedAt", LlegoAPI.DateTime?.self),
          .field("refundReason", String?.self),
          .field("refundedAt", LlegoAPI.DateTime?.self),
          .field("refundAmount", Double?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RequestRefundMutation.Data.RequestRefund.self
        ] }

        /// Payment attempt ID
        public var id: String { __data["id"] }
        /// Current status
        public var status: GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum> { __data["status"] }
        /// When refund was requested
        public var refundRequestedAt: LlegoAPI.DateTime? { __data["refundRequestedAt"] }
        /// Refund reason
        public var refundReason: String? { __data["refundReason"] }
        /// When refund completed
        public var refundedAt: LlegoAPI.DateTime? { __data["refundedAt"] }
        /// Refund amount
        public var refundAmount: Double? { __data["refundAmount"] }
      }
    }
  }

}