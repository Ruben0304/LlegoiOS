// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductRecommendationsQuery: GraphQLQuery {
    public static let operationName: String = "GetProductRecommendations"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProductRecommendations($productIds: [String!]!, $limit: Int!, $jwt: String) { productRecommendations(productIds: $productIds, limit: $limit, jwt: $jwt) { __typename reasoning recommendations { __typename productId productName reasoning product { __typename id name description price currency imageUrlBaja availability } } } }"#
      ))

    public var productIds: [String]
    public var limit: Int32
    public var jwt: GraphQLNullable<String>

    public init(
      productIds: [String],
      limit: Int32,
      jwt: GraphQLNullable<String>
    ) {
      self.productIds = productIds
      self.limit = limit
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "productIds": productIds,
      "limit": limit,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("productRecommendations", ProductRecommendations?.self, arguments: [
          "productIds": .variable("productIds"),
          "limit": .variable("limit"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductRecommendationsQuery.Data.self
      ] }

      /// Obtener recomendaciones de productos complementarios basadas en items del carrito
      public var productRecommendations: ProductRecommendations? { __data["productRecommendations"] }

      /// ProductRecommendations
      ///
      /// Parent Type: `ProductRecommendationsResponseType`
      public struct ProductRecommendations: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductRecommendationsResponseType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("reasoning", String.self),
          .field("recommendations", [Recommendation].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductRecommendationsQuery.Data.ProductRecommendations.self
        ] }

        public var reasoning: String { __data["reasoning"] }
        public var recommendations: [Recommendation] { __data["recommendations"] }

        /// ProductRecommendations.Recommendation
        ///
        /// Parent Type: `ProductRecommendationType`
        public struct Recommendation: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductRecommendationType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("productId", String.self),
            .field("productName", String.self),
            .field("reasoning", String.self),
            .field("product", Product?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductRecommendationsQuery.Data.ProductRecommendations.Recommendation.self
          ] }

          public var productId: String { __data["productId"] }
          public var productName: String { __data["productName"] }
          public var reasoning: String { __data["reasoning"] }
          /// Full product details
          public var product: Product? { __data["product"] }

          /// ProductRecommendations.Recommendation.Product
          ///
          /// Parent Type: `ProductType`
          public struct Product: LlegoAPI.SelectionSet {
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
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductRecommendationsQuery.Data.ProductRecommendations.Recommendation.Product.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var description: String { __data["description"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the low quality product image (720x540)
            public var imageUrlBaja: String { __data["imageUrlBaja"] }
            public var availability: Bool { __data["availability"] }
          }
        }
      }
    }
  }

}