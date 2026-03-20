// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct InitiateTrondealerPaymentMutation: GraphQLMutation {
    public static let operationName: String = "InitiateTrondealerPayment"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation InitiateTrondealerPayment($orderId: String!, $jwt: String!) { initiateTrondealerPayment(orderId: $orderId, jwt: $jwt) { __typename address expectedAmount token network orderId } }"#
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
        .field("initiateTrondealerPayment", InitiateTrondealerPayment.self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        InitiateTrondealerPaymentMutation.Data.self
      ] }

      /// Iniciar pago con USDT/TronDealer para un pedido
      public var initiateTrondealerPayment: InitiateTrondealerPayment { __data["initiateTrondealerPayment"] }

      /// InitiateTrondealerPayment
      ///
      /// Parent Type: `TronDealerPaymentResult`
      public struct InitiateTrondealerPayment: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.TronDealerPaymentResult }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("address", String.self),
          .field("expectedAmount", Double.self),
          .field("token", String.self),
          .field("network", String?.self),
          .field("orderId", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          InitiateTrondealerPaymentMutation.Data.InitiateTrondealerPayment.self
        ] }

        /// Dirección de wallet TRON a la que enviar el USDT
        public var address: String { __data["address"] }
        /// Monto exacto en USDT a enviar
        public var expectedAmount: Double { __data["expectedAmount"] }
        /// Token a usar, generalmente USDT
        public var token: String { __data["token"] }
        /// Red blockchain, generalmente TRON
        public var network: String? { __data["network"] }
        /// ID de la orden asociada
        public var orderId: String { __data["orderId"] }
      }
    }
  }

}