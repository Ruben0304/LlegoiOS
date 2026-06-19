// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchProductsForAIQuery: GraphQLQuery {
    public static let operationName: String = "GetBranchProductsForAI"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranchProductsForAI($productId: String!, $limit: Int! = 50, $jwt: String) { productsFromSameBranch(productId: $productId, limit: $limit, jwt: $jwt) { __typename id name description price currency imageUrlBaja availability branchId } }"#
      ))

    public var productId: String
    public var limit: Int32
    public var jwt: GraphQLNullable<String>

    public init(
      productId: String,
      limit: Int32 = 50,
      jwt: GraphQLNullable<String>
    ) {
      self.productId = productId
      self.limit = limit
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "productId": productId,
      "limit": limit,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("productsFromSameBranch", [ProductsFromSameBranch].self, arguments: [
          "productId": .variable("productId"),
          "limit": .variable("limit"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchProductsForAIQuery.Data.self
      ] }

      /// Obtener productos de la misma branch/sucursal, excluyendo el producto dado
      public var productsFromSameBranch: [ProductsFromSameBranch] { __data["productsFromSameBranch"] }

      /// ProductsFromSameBranch
      ///
      /// Parent Type: `ProductType`
      public struct ProductsFromSameBranch: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("price", Double.self),
          .field("currency", String.self),
          .field("imageUrlBaja", String.self),
          .field("availability", Bool.self),
          .field("branchId", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBranchProductsForAIQuery.Data.ProductsFromSameBranch.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Presigned URL for the low quality product image (720x540)
        public var imageUrlBaja: String { __data["imageUrlBaja"] }
        public var availability: Bool { __data["availability"] }
        public var branchId: String { __data["branchId"] }
      }
    }
  }

}