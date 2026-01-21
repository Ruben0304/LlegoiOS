// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct InitiatePaymentMutation: GraphQLMutation {
    public static let operationName: String = "InitiatePayment"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation InitiatePayment($orderId: String!, $paymentMethodId: String!, $jwt: String!, $includeDeliveryFee: Boolean!) { initiatePayment( orderId: $orderId paymentMethodId: $paymentMethodId jwt: $jwt includeDeliveryFee: $includeDeliveryFee ) { __typename paymentAttempt { __typename id orderId paymentMethodId subtotal deliveryFee includesDeliveryFee taxAmount discountAmount commissionAmount totalAmount currency status stripePaymentIntentId stripeClientSecret proofUrl customerConfirmedAt businessConfirmedAt disputeReason deliveryPersonConfirmedAt deliveryPersonId walletTransactionId businessWalletTransactionId commissionTransactionId } instructions } }"#
      ))

    public var orderId: String
    public var paymentMethodId: String
    public var jwt: String
    public var includeDeliveryFee: Bool

    public init(
      orderId: String,
      paymentMethodId: String,
      jwt: String,
      includeDeliveryFee: Bool
    ) {
      self.orderId = orderId
      self.paymentMethodId = paymentMethodId
      self.jwt = jwt
      self.includeDeliveryFee = includeDeliveryFee
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "orderId": orderId,
      "paymentMethodId": paymentMethodId,
      "jwt": jwt,
      "includeDeliveryFee": includeDeliveryFee
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("initiatePayment", InitiatePayment.self, arguments: [
          "orderId": .variable("orderId"),
          "paymentMethodId": .variable("paymentMethodId"),
          "jwt": .variable("jwt"),
          "includeDeliveryFee": .variable("includeDeliveryFee")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        InitiatePaymentMutation.Data.self
      ] }

      /// Iniciar un pago para un pedido
      public var initiatePayment: InitiatePayment { __data["initiatePayment"] }

      /// InitiatePayment
      ///
      /// Parent Type: `InitiatePaymentResult`
      public struct InitiatePayment: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.InitiatePaymentResult }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("paymentAttempt", PaymentAttempt.self),
          .field("instructions", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          InitiatePaymentMutation.Data.InitiatePayment.self
        ] }

        /// The created payment attempt
        public var paymentAttempt: PaymentAttempt { __data["paymentAttempt"] }
        /// Instructions for completing payment (for manual methods)
        public var instructions: String? { __data["instructions"] }

        /// InitiatePayment.PaymentAttempt
        ///
        /// Parent Type: `PaymentAttemptType`
        public struct PaymentAttempt: LlegoAPI.SelectionSet {
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
            .field("stripePaymentIntentId", String?.self),
            .field("stripeClientSecret", String?.self),
            .field("proofUrl", String?.self),
            .field("customerConfirmedAt", LlegoAPI.DateTime?.self),
            .field("businessConfirmedAt", LlegoAPI.DateTime?.self),
            .field("disputeReason", String?.self),
            .field("deliveryPersonConfirmedAt", LlegoAPI.DateTime?.self),
            .field("deliveryPersonId", String?.self),
            .field("walletTransactionId", String?.self),
            .field("businessWalletTransactionId", String?.self),
            .field("commissionTransactionId", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            InitiatePaymentMutation.Data.InitiatePayment.PaymentAttempt.self
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
          /// Stripe Payment Intent ID
          public var stripePaymentIntentId: String? { __data["stripePaymentIntentId"] }
          /// Stripe client secret for UI
          public var stripeClientSecret: String? { __data["stripeClientSecret"] }
          /// Proof/receipt URL
          public var proofUrl: String? { __data["proofUrl"] }
          /// When customer confirmed
          public var customerConfirmedAt: LlegoAPI.DateTime? { __data["customerConfirmedAt"] }
          /// When business confirmed
          public var businessConfirmedAt: LlegoAPI.DateTime? { __data["businessConfirmedAt"] }
          /// Dispute reason if disputed
          public var disputeReason: String? { __data["disputeReason"] }
          /// When delivery confirmed cash
          public var deliveryPersonConfirmedAt: LlegoAPI.DateTime? { __data["deliveryPersonConfirmedAt"] }
          /// Delivery person who confirmed
          public var deliveryPersonId: String? { __data["deliveryPersonId"] }
          /// User wallet transaction ID
          public var walletTransactionId: String? { __data["walletTransactionId"] }
          /// Business wallet transaction ID
          public var businessWalletTransactionId: String? { __data["businessWalletTransactionId"] }
          /// Commission transaction ID
          public var commissionTransactionId: String? { __data["commissionTransactionId"] }
        }
      }
    }
  }

}