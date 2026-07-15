// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetOrderPaymentAttemptsQuery: GraphQLQuery {
    public static let operationName: String = "GetOrderPaymentAttempts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetOrderPaymentAttempts($orderId: String!, $jwt: String!) { paymentAttemptsByOrder(orderId: $orderId, jwt: $jwt) { __typename id status totalAmount currency refundRequestedAt refundReason refundedAt refundAmount } }"#
      ))

    public var orderId: String
    public var jwt: String

    public init(
      orderId: String,
      jwt: String
    ) {
      self.orderId = orderId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "orderId": orderId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("paymentAttemptsByOrder", [PaymentAttemptsByOrder].self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetOrderPaymentAttemptsQuery.Data.self
      ] }

      /// Obtener intentos de pago de un pedido
      public var paymentAttemptsByOrder: [PaymentAttemptsByOrder] { __data["paymentAttemptsByOrder"] }

      /// PaymentAttemptsByOrder
      ///
      /// Parent Type: `PaymentAttemptType`
      public struct PaymentAttemptsByOrder: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentAttemptType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("status", GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum>.self),
          .field("totalAmount", Double.self),
          .field("currency", String.self),
          .field("refundRequestedAt", LlegoAPI.DateTime?.self),
          .field("refundReason", String?.self),
          .field("refundedAt", LlegoAPI.DateTime?.self),
          .field("refundAmount", Double?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetOrderPaymentAttemptsQuery.Data.PaymentAttemptsByOrder.self
        ] }

        /// Payment attempt ID
        public var id: String { __data["id"] }
        /// Current status
        public var status: GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum> { __data["status"] }
        /// Total to pay
        public var totalAmount: Double { __data["totalAmount"] }
        /// Currency (usd or local)
        public var currency: String { __data["currency"] }
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