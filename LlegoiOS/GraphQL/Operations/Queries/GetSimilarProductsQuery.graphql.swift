// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetSimilarProductsQuery: GraphQLQuery {
    public static let operationName: String = "GetSimilarProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetSimilarProducts($productId: String!, $limit: Int, $jwt: String) { getSimilarProducts(productId: $productId, limit: $limit, jwt: $jwt) { __typename id branchId name description weight price currency imageUrlBaja availability createdAt business { __typename id name avatarUrl } } }"#
      ))

    public var productId: String
    public var limit: GraphQLNullable<Int32>
    public var jwt: GraphQLNullable<String>

    public init(
      productId: String,
      limit: GraphQLNullable<Int32>,
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
        .field("getSimilarProducts", [GetSimilarProduct].self, arguments: [
          "productId": .variable("productId"),
          "limit": .variable("limit"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetSimilarProductsQuery.Data.self
      ] }

      /// Productos similares al dado usando Qdrant recommend
      public var getSimilarProducts: [GetSimilarProduct] { __data["getSimilarProducts"] }

      /// GetSimilarProduct
      ///
      /// Parent Type: `ProductType`
      public struct GetSimilarProduct: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("branchId", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("weight", String.self),
          .field("price", Double.self),
          .field("currency", String.self),
          .field("imageUrlBaja", String.self),
          .field("availability", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("business", Business?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetSimilarProductsQuery.Data.GetSimilarProduct.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Presigned URL for the low quality product image (720x540)
        public var imageUrlBaja: String { __data["imageUrlBaja"] }
        public var availability: Bool { __data["availability"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Business associated with this product (through branch)
        public var business: Business? { __data["business"] }

        /// GetSimilarProduct.Business
        ///
        /// Parent Type: `BusinessType`
        public struct Business: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("avatarUrl", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetSimilarProductsQuery.Data.GetSimilarProduct.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the business avatar
          public var avatarUrl: String? { __data["avatarUrl"] }
        }
      }
    }
  }

}