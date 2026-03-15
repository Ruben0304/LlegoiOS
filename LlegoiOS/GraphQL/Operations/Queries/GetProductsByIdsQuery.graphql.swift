// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductsByIdsQuery: GraphQLQuery {
    public static let operationName: String = "GetProductsByIds"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProductsByIds($ids: [String!]!, $jwt: String) { productsByIds(ids: $ids, jwt: $jwt) { __typename id branchId name weight price currency convertedPrice convertedCurrency exchangeRate imageUrlMuyBaja availability business { __typename name } } }"#
      ))

    public var ids: [String]
    public var jwt: GraphQLNullable<String>

    public init(
      ids: [String],
      jwt: GraphQLNullable<String>
    ) {
      self.ids = ids
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "ids": ids,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("productsByIds", [ProductsById].self, arguments: [
          "ids": .variable("ids"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductsByIdsQuery.Data.self
      ] }

      /// Obtener múltiples productos por lista de IDs (findMany)
      public var productsByIds: [ProductsById] { __data["productsByIds"] }

      /// ProductsById
      ///
      /// Parent Type: `ProductType`
      public struct ProductsById: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("branchId", String.self),
          .field("name", String.self),
          .field("weight", String.self),
          .field("price", Double.self),
          .field("currency", String.self),
          .field("convertedPrice", Double?.self),
          .field("convertedCurrency", String?.self),
          .field("exchangeRate", Int?.self),
          .field("imageUrlMuyBaja", String.self),
          .field("availability", Bool.self),
          .field("business", Business?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductsByIdsQuery.Data.ProductsById.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Precio convertido a la otra moneda (si la sucursal acepta ambas)
        public var convertedPrice: Double? { __data["convertedPrice"] }
        /// Moneda del precio convertido
        public var convertedCurrency: String? { __data["convertedCurrency"] }
        /// Tasa de cambio de la sucursal (si acepta ambas monedas)
        public var exchangeRate: Int? { __data["exchangeRate"] }
        /// Presigned URL for the very low quality product image (200x200)
        public var imageUrlMuyBaja: String { __data["imageUrlMuyBaja"] }
        public var availability: Bool { __data["availability"] }
        /// Business associated with this product (through branch)
        public var business: Business? { __data["business"] }

        /// ProductsById.Business
        ///
        /// Parent Type: `BusinessType`
        public struct Business: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("name", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductsByIdsQuery.Data.ProductsById.Business.self
          ] }

          public var name: String { __data["name"] }
        }
      }
    }
  }

}