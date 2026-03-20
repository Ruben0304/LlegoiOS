// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct InitiateQvapayPaymentMutation: GraphQLMutation {
    public static let operationName: String = "InitiateQvapayPayment"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation InitiateQvapayPayment($orderId: String!, $jwt: String!) { initiateQvapayPayment(orderId: $orderId, jwt: $jwt) { __typename paymentUrl transactionUuid amount orderId } }"#
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

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("initiateQvapayPayment", InitiateQvapayPayment.self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        InitiateQvapayPaymentMutation.Data.self
      ] }

      /// Iniciar pago con QvaPay para un pedido
      public var initiateQvapayPayment: InitiateQvapayPayment { __data["initiateQvapayPayment"] }

      /// InitiateQvapayPayment
      ///
      /// Parent Type: `QvaPayPaymentResult`
      public struct InitiateQvapayPayment: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.QvaPayPaymentResult }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("paymentUrl", String.self),
          .field("transactionUuid", String.self),
          .field("amount", Double.self),
          .field("orderId", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          InitiateQvapayPaymentMutation.Data.InitiateQvapayPayment.self
        ] }

        /// URL de pago QvaPay — abrir en WebView o browser
        public var paymentUrl: String { __data["paymentUrl"] }
        /// UUID de la transacción en QvaPay
        public var transactionUuid: String { __data["transactionUuid"] }
        /// Monto a pagar en USD
        public var amount: Double { __data["amount"] }
        /// ID de la orden asociada
        public var orderId: String { __data["orderId"] }
      }
    }
  }

}