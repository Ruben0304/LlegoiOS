// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchesForProductQuery: GraphQLQuery {
    public static let operationName: String = "GetBranchesForProduct"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranchesForProduct($productId: String!, $limit: Int, $jwt: String) { getBranchesForProduct(productId: $productId, limit: $limit, jwt: $jwt) { __typename id businessId name address avatarUrl avatarUrlBaja avatarUrlAlta coverUrl coverUrlBaja coverUrlAlta deliveryRadius catalogOnly createdAt products(limit: 2, availableOnly: false) { __typename id name price currency imageUrlBaja } } }"#
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
        .field("getBranchesForProduct", [GetBranchesForProduct].self, arguments: [
          "productId": .variable("productId"),
          "limit": .variable("limit"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchesForProductQuery.Data.self
      ] }

      /// Sucursales con más productos similares al producto dado
      public var getBranchesForProduct: [GetBranchesForProduct] { __data["getBranchesForProduct"] }

      /// GetBranchesForProduct
      ///
      /// Parent Type: `BranchType`
      public struct GetBranchesForProduct: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("businessId", String.self),
          .field("name", String.self),
          .field("address", String?.self),
          .field("avatarUrl", String?.self),
          .field("avatarUrlBaja", String?.self),
          .field("avatarUrlAlta", String?.self),
          .field("coverUrl", String?.self),
          .field("coverUrlBaja", String?.self),
          .field("coverUrlAlta", String?.self),
          .field("deliveryRadius", Double?.self),
          .field("catalogOnly", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("products", [Product].self, arguments: [
            "limit": 2,
            "availableOnly": false
          ]),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBranchesForProductQuery.Data.GetBranchesForProduct.self
        ] }

        public var id: String { __data["id"] }
        public var businessId: String { __data["businessId"] }
        public var name: String { __data["name"] }
        public var address: String? { __data["address"] }
        /// Presigned URL for the branch avatar (inherits from business if not set)
        public var avatarUrl: String? { __data["avatarUrl"] }
        /// Presigned URL for low quality branch avatar (inherits business avatar and falls back to original)
        public var avatarUrlBaja: String? { __data["avatarUrlBaja"] }
        /// Presigned URL for high quality branch avatar (inherits business avatar and falls back to original)
        public var avatarUrlAlta: String? { __data["avatarUrlAlta"] }
        /// Presigned URL for the branch cover image
        public var coverUrl: String? { __data["coverUrl"] }
        /// Presigned URL for low quality branch cover (with fallback to original)
        public var coverUrlBaja: String? { __data["coverUrlBaja"] }
        /// Presigned URL for high quality branch cover (with fallback to original)
        public var coverUrlAlta: String? { __data["coverUrlAlta"] }
        public var deliveryRadius: Double? { __data["deliveryRadius"] }
        public var catalogOnly: Bool { __data["catalogOnly"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Products from this branch
        public var products: [Product] { __data["products"] }

        /// GetBranchesForProduct.Product
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
            .field("price", Double.self),
            .field("currency", String.self),
            .field("imageUrlBaja", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBranchesForProductQuery.Data.GetBranchesForProduct.Product.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var price: Double { __data["price"] }
          public var currency: String { __data["currency"] }
          /// Presigned URL for the low quality product image (720x540)
          public var imageUrlBaja: String { __data["imageUrlBaja"] }
        }
      }
    }
  }

}