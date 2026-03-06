// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetCartProductsQuery: GraphQLQuery {
    public static let operationName: String = "GetCartProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetCartProducts($first: Int! = 100, $after: String, $ids: [String!]!) { products(first: $first, after: $after, ids: $ids) { __typename edges { __typename node { __typename id branchId name description weight price currency imageUrlBaja availability createdAt business { __typename id name } } cursor } pageInfo { __typename hasNextPage hasPreviousPage startCursor endCursor totalCount } } }"#
      ))

    public var first: Int32
    public var after: GraphQLNullable<String>
    public var ids: [String]

    public init(
      first: Int32 = 100,
      after: GraphQLNullable<String>,
      ids: [String]
    ) {
      self.first = first
      self.after = after
      self.ids = ids
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "first": first,
      "after": after,
      "ids": ids
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("products", Products.self, arguments: [
          "first": .variable("first"),
          "after": .variable("after"),
          "ids": .variable("ids")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetCartProductsQuery.Data.self
      ] }

      /// Lista de productos con scoring por cercanía (paginado)
      public var products: Products { __data["products"] }

      /// Products
      ///
      /// Parent Type: `ProductConnection`
      public struct Products: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCartProductsQuery.Data.Products.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }

        /// Products.Edge
        ///
        /// Parent Type: `ProductEdge`
        public struct Edge: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductEdge }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
            .field("cursor", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetCartProductsQuery.Data.Products.Edge.self
          ] }

          public var node: Node { __data["node"] }
          public var cursor: String { __data["cursor"] }

          /// Products.Edge.Node
          ///
          /// Parent Type: `ScoredProductType`
          public struct Node: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ScoredProductType }
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
              GetCartProductsQuery.Data.Products.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var branchId: String { __data["branchId"] }
            public var name: String { __data["name"] }
            public var description: String { __data["description"] }
            public var weight: String { __data["weight"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the low quality product image (100x100)
            public var imageUrlBaja: String { __data["imageUrlBaja"] }
            public var availability: Bool { __data["availability"] }
            public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

            /// Products.Edge.Node.Business
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
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetCartProductsQuery.Data.Products.Edge.Node.Business.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
            }
          }
        }

        /// Products.PageInfo
        ///
        /// Parent Type: `PageInfo`
        public struct PageInfo: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PageInfo }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("hasNextPage", Bool.self),
            .field("hasPreviousPage", Bool.self),
            .field("startCursor", String?.self),
            .field("endCursor", String?.self),
            .field("totalCount", Int.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetCartProductsQuery.Data.Products.PageInfo.self
          ] }

          public var hasNextPage: Bool { __data["hasNextPage"] }
          public var hasPreviousPage: Bool { __data["hasPreviousPage"] }
          public var startCursor: String? { __data["startCursor"] }
          public var endCursor: String? { __data["endCursor"] }
          public var totalCount: Int { __data["totalCount"] }
        }
      }
    }
  }

}