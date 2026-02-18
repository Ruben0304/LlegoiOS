// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetPaymentMethodsQuery: GraphQLQuery {
    public static let operationName: String = "GetPaymentMethods"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetPaymentMethods($jwt: String, $branchId: String) { paymentMethods(jwt: $jwt, branchId: $branchId) { __typename id name code currency method commissionPercent deliveryFeePercent isRefundable requiresProof requiresBusinessConfirmation expirationMinutes isActive displayOrder iconUrl instructions } }"#
      ))

    public var jwt: GraphQLNullable<String>
    public var branchId: GraphQLNullable<String>

    public init(
      jwt: GraphQLNullable<String>,
      branchId: GraphQLNullable<String>
    ) {
      self.jwt = jwt
      self.branchId = branchId
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "jwt": jwt,
      "branchId": branchId
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("paymentMethods", [PaymentMethod].self, arguments: [
          "jwt": .variable("jwt"),
          "branchId": .variable("branchId")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetPaymentMethodsQuery.Data.self
      ] }

      /// Obtener todos los métodos de pago disponibles. Si se provee branchId, retorna solo los aceptados por ese branch.
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
        /// Display name
        public var name: String { __data["name"] }
        /// Internal code
        public var code: String { __data["code"] }
        /// Currency code
        public var currency: String { __data["currency"] }
        /// Method type
        public var method: String { __data["method"] }
        /// Commission percentage charged
        public var commissionPercent: Double { __data["commissionPercent"] }
        /// Delivery fee percentage
        public var deliveryFeePercent: Double { __data["deliveryFeePercent"] }
        /// Whether refunds are allowed
        public var isRefundable: Bool { __data["isRefundable"] }
        /// Whether proof is required
        public var requiresProof: Bool { __data["requiresProof"] }
        /// Whether business confirmation is required
        public var requiresBusinessConfirmation: Bool { __data["requiresBusinessConfirmation"] }
        /// Expiration in minutes
        public var expirationMinutes: Int? { __data["expirationMinutes"] }
        /// Whether method is active
        public var isActive: Bool { __data["isActive"] }
        /// Display order
        public var displayOrder: Int { __data["displayOrder"] }
        /// Icon URL
        public var iconUrl: String? { __data["iconUrl"] }
        /// Payment instructions
        public var instructions: String? { __data["instructions"] }
      }
    }
  }

}