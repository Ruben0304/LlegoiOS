// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetPaymentMethodsQuery: GraphQLQuery {
    public static let operationName: String = "GetPaymentMethods"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetPaymentMethods($jwt: String) { paymentMethods(jwt: $jwt) { __typename id name code currency method commissionPercent deliveryFeePercent isRefundable requiresProof requiresBusinessConfirmation expirationMinutes isActive displayOrder iconUrl instructions } }"#
      ))

    public var jwt: GraphQLNullable<String>

    public init(jwt: GraphQLNullable<String>) {
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { ["jwt": jwt] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("paymentMethods", [PaymentMethod].self, arguments: ["jwt": .variable("jwt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetPaymentMethodsQuery.Data.self
      ] }

      /// Obtener todos los métodos de pago disponibles
      public var paymentMethods: [PaymentMethod] { __data["paymentMethods"] }

      /// PaymentMethod
      ///
      /// Parent Type: `PaymentMethodType`
      public struct PaymentMethod: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentMethodType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("code", String.self),
          .field("currency", String.self),
          .field("method", String.self),
          .field("commissionPercent", Double.self),
          .field("deliveryFeePercent", Double.self),
          .field("isRefundable", Bool.self),
          .field("requiresProof", Bool.self),
          .field("requiresBusinessConfirmation", Bool.self),
          .field("expirationMinutes", Int?.self),
          .field("isActive", Bool.self),
          .field("displayOrder", Int.self),
          .field("iconUrl", String?.self),
          .field("instructions", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetPaymentMethodsQuery.Data.PaymentMethod.self
        ] }

        /// Payment method ID
        public var id: String { __data["id"] }
        /// Display name (e.g., Wallet USD, Transfermóvil)
        public var name: String { __data["name"] }
        /// Code (e.g., wallet_usd, transfermovil)
        public var code: String { __data["code"] }
        /// Currency (e.g., CUP, USD)
        public var currency: String { __data["currency"] }
        /// Payment method type (wallet, transfer, stripe, cash)
        public var method: String { __data["method"] }
        /// Commission percentage charged to customer
        public var commissionPercent: Double { __data["commissionPercent"] }
        /// Extra percentage for cash delivery payments
        public var deliveryFeePercent: Double { __data["deliveryFeePercent"] }
        /// Whether this method supports refunds
        public var isRefundable: Bool { __data["isRefundable"] }
        /// Whether proof/receipt is required
        public var requiresProof: Bool { __data["requiresProof"] }
        /// Whether business must confirm receipt
        public var requiresBusinessConfirmation: Bool { __data["requiresBusinessConfirmation"] }
        /// Time limit to complete payment
        public var expirationMinutes: Int? { __data["expirationMinutes"] }
        /// Whether this method is currently active
        public var isActive: Bool { __data["isActive"] }
        /// Display order in UI
        public var displayOrder: Int { __data["displayOrder"] }
        /// Icon URL
        public var iconUrl: String? { __data["iconUrl"] }
        /// Payment instructions for user
        public var instructions: String? { __data["instructions"] }
      }
    }
  }

}