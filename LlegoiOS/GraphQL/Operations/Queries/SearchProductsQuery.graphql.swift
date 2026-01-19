// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchProductsQuery: GraphQLQuery {
    public static let operationName: String = "SearchProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchProducts($query: String!, $first: Int! = 20, $after: String, $useVectorSearch: Boolean, $branchTipo: BranchTipo, $radiusKm: Float, $jwt: String) { searchProducts( query: $query first: $first after: $after useVectorSearch: $useVectorSearch branchTipo: $branchTipo radiusKm: $radiusKm jwt: $jwt ) { __typename edges { __typename node { __typename id branchId name description weight price currency imageUrl availability createdAt distanceKm score categoryId category { __typename id branchType name iconIos iconWeb iconAndroid } business { __typename id name avatarUrl } } cursor } pageInfo { __typename hasNextPage hasPreviousPage startCursor endCursor totalCount } } }"#
      ))

    public var query: String
    public var first: Int32
    public var after: GraphQLNullable<String>
    public var useVectorSearch: GraphQLNullable<Bool>
    public var branchTipo: GraphQLNullable<GraphQLEnum<BranchTipo>>
    public var radiusKm: GraphQLNullable<Double>
    public var jwt: GraphQLNullable<String>

    public init(
      query: String,
      first: Int32 = 20,
      after: GraphQLNullable<String>,
      useVectorSearch: GraphQLNullable<Bool>,
      branchTipo: GraphQLNullable<GraphQLEnum<BranchTipo>>,
      radiusKm: GraphQLNullable<Double>,
      jwt: GraphQLNullable<String>
    ) {
      self.query = query
      self.first = first
      self.after = after
      self.useVectorSearch = useVectorSearch
      self.branchTipo = branchTipo
      self.radiusKm = radiusKm
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "first": first,
      "after": after,
      "useVectorSearch": useVectorSearch,
      "branchTipo": branchTipo,
      "radiusKm": radiusKm,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchProducts", SearchProducts.self, arguments: [
          "query": .variable("query"),
          "first": .variable("first"),
          "after": .variable("after"),
          "useVectorSearch": .variable("useVectorSearch"),
          "branchTipo": .variable("branchTipo"),
          "radiusKm": .variable("radiusKm"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchProductsQuery.Data.self
      ] }

      /// Buscar productos con scoring por cercanía (paginado)
      public var searchProducts: SearchProducts { __data["searchProducts"] }

      /// SearchProducts
      ///
      /// Parent Type: `ProductConnection`
      public struct SearchProducts: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchProductsQuery.Data.SearchProducts.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }

        /// SearchProducts.Edge
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
            SearchProductsQuery.Data.SearchProducts.Edge.self
          ] }

          public var node: Node { __data["node"] }
          public var cursor: String { __data["cursor"] }

          /// SearchProducts.Edge.Node
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
              .field("imageUrl", String.self),
              .field("availability", Bool.self),
              .field("createdAt", LlegoAPI.DateTime.self),
              .field("distanceKm", Double?.self),
              .field("score", Double.self),
              .field("categoryId", String?.self),
              .field("category", Category?.self),
              .field("business", Business?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SearchProductsQuery.Data.SearchProducts.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var branchId: String { __data["branchId"] }
            public var name: String { __data["name"] }
            public var description: String { __data["description"] }
            public var weight: String { __data["weight"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
            public var availability: Bool { __data["availability"] }
            public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            public var score: Double { __data["score"] }
            public var categoryId: String? { __data["categoryId"] }
            /// Product category
            public var category: Category? { __data["category"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

            /// SearchProducts.Edge.Node.Category
            ///
            /// Parent Type: `ProductCategoryType`
            public struct Category: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductCategoryType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("branchType", String.self),
                .field("name", String.self),
                .field("iconIos", String.self),
                .field("iconWeb", String.self),
                .field("iconAndroid", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                SearchProductsQuery.Data.SearchProducts.Edge.Node.Category.self
              ] }

              public var id: String { __data["id"] }
              public var branchType: String { __data["branchType"] }
              public var name: String { __data["name"] }
              public var iconIos: String { __data["iconIos"] }
              public var iconWeb: String { __data["iconWeb"] }
              public var iconAndroid: String { __data["iconAndroid"] }
            }

            /// SearchProducts.Edge.Node.Business
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
                SearchProductsQuery.Data.SearchProducts.Edge.Node.Business.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the business avatar
              public var avatarUrl: String? { __data["avatarUrl"] }
            }
          }
        }

        /// SearchProducts.PageInfo
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
            SearchProductsQuery.Data.SearchProducts.PageInfo.self
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