// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct ConfirmPaymentSentMutation: GraphQLMutation {
    public static let operationName: String = "ConfirmPaymentSent"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ConfirmPaymentSent($paymentAttemptId: String!, $proofUrl: String!, $jwt: String!) { confirmPaymentSent( paymentAttemptId: $paymentAttemptId proofUrl: $proofUrl jwt: $jwt ) { __typename id orderId paymentMethodId subtotal deliveryFee includesDeliveryFee taxAmount discountAmount commissionAmount totalAmount currency status sendsSmsNotification proofUrl customerConfirmedAt businessConfirmedAt } }"#
      ))

    public var paymentAttemptId: String
    public var proofUrl: String
    public var jwt: String

    public init(
      paymentAttemptId: String,
      proofUrl: String,
      jwt: String
    ) {
      self.paymentAttemptId = paymentAttemptId
      self.proofUrl = proofUrl
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "paymentAttemptId": paymentAttemptId,
      "proofUrl": proofUrl,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("confirmPaymentSent", ConfirmPaymentSent.self, arguments: [
          "paymentAttemptId": .variable("paymentAttemptId"),
          "proofUrl": .variable("proofUrl"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ConfirmPaymentSentMutation.Data.self
      ] }

      /// Confirmar que el cliente envió el pago (para métodos manuales)
      public var confirmPaymentSent: ConfirmPaymentSent { __data["confirmPaymentSent"] }

      /// ConfirmPaymentSent
      ///
      /// Parent Type: `PaymentAttemptType`
      public struct ConfirmPaymentSent: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentAttemptType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("orderId", String.self),
          .field("paymentMethodId", String.self),
          .field("subtotal", Double.self),
          .field("deliveryFee", Double.self),
          .field("includesDeliveryFee", Bool.self),
          .field("taxAmount", Double.self),
          .field("discountAmount", Double.self),
          .field("commissionAmount", Double.self),
          .field("totalAmount", Double.self),
          .field("currency", String.self),
          .field("status", GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum>.self),
          .field("sendsSmsNotification", Bool.self),
          .field("proofUrl", String?.self),
          .field("customerConfirmedAt", LlegoAPI.DateTime?.self),
          .field("businessConfirmedAt", LlegoAPI.DateTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ConfirmPaymentSentMutation.Data.ConfirmPaymentSent.self
        ] }

        /// Payment attempt ID
        public var id: String { __data["id"] }
        /// Order ID
        public var orderId: String { __data["orderId"] }
        /// Payment method ID
        public var paymentMethodId: String { __data["paymentMethodId"] }
        /// Order subtotal
        public var subtotal: Double { __data["subtotal"] }
        /// Delivery fee
        public var deliveryFee: Double { __data["deliveryFee"] }
        /// Whether delivery is included
        public var includesDeliveryFee: Bool { __data["includesDeliveryFee"] }
        /// Tax amount
        public var taxAmount: Double { __data["taxAmount"] }
        /// Discount amount
        public var discountAmount: Double { __data["discountAmount"] }
        /// Commission charged
        public var commissionAmount: Double { __data["commissionAmount"] }
        /// Total to pay
        public var totalAmount: Double { __data["totalAmount"] }
        /// Currency (usd or local)
        public var currency: String { __data["currency"] }
        /// Current status
        public var status: GraphQLEnum<LlegoAPI.PaymentAttemptStatusEnum> { __data["status"] }
        /// User indicated their transfer sends SMS (enables Shortcut auto-confirm)
        public var sendsSmsNotification: Bool { __data["sendsSmsNotification"] }
        /// Proof/receipt URL
        public var proofUrl: String? { __data["proofUrl"] }
        /// When customer confirmed
        public var customerConfirmedAt: LlegoAPI.DateTime? { __data["customerConfirmedAt"] }
        /// When business confirmed
        public var businessConfirmedAt: LlegoAPI.DateTime? { __data["businessConfirmedAt"] }
      }
    }
  }

}