// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchBranchesQuery: GraphQLQuery {
    public static let operationName: String = "SearchBranches"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchBranches($query: String!, $first: Int! = 20, $after: String, $useVectorSearch: Boolean, $productCategoryId: String, $radiusKm: Float, $jwt: String) { searchBranches( query: $query first: $first after: $after useVectorSearch: $useVectorSearch productCategoryId: $productCategoryId radiusKm: $radiusKm jwt: $jwt ) { __typename edges { __typename node { __typename id businessId name address coordinates { __typename type coordinates } phone status avatarUrl coverUrl deliveryRadius createdAt score distanceKm products(limit: 4, availableOnly: false) { __typename id name price currency imageUrlBaja availability } } cursor } pageInfo { __typename hasNextPage hasPreviousPage startCursor endCursor totalCount } } }"#
      ))

    public var query: String
    public var first: Int32
    public var after: GraphQLNullable<String>
    public var useVectorSearch: GraphQLNullable<Bool>
    public var productCategoryId: GraphQLNullable<String>
    public var radiusKm: GraphQLNullable<Double>
    public var jwt: GraphQLNullable<String>

    public init(
      query: String,
      first: Int32 = 20,
      after: GraphQLNullable<String>,
      useVectorSearch: GraphQLNullable<Bool>,
      productCategoryId: GraphQLNullable<String>,
      radiusKm: GraphQLNullable<Double>,
      jwt: GraphQLNullable<String>
    ) {
      self.query = query
      self.first = first
      self.after = after
      self.useVectorSearch = useVectorSearch
      self.productCategoryId = productCategoryId
      self.radiusKm = radiusKm
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "first": first,
      "after": after,
      "useVectorSearch": useVectorSearch,
      "productCategoryId": productCategoryId,
      "radiusKm": radiusKm,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchBranches", SearchBranches.self, arguments: [
          "query": .variable("query"),
          "first": .variable("first"),
          "after": .variable("after"),
          "useVectorSearch": .variable("useVectorSearch"),
          "productCategoryId": .variable("productCategoryId"),
          "radiusKm": .variable("radiusKm"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchBranchesQuery.Data.self
      ] }

      /// Buscar sucursales con scoring por cercanía (paginado)
      public var searchBranches: SearchBranches { __data["searchBranches"] }

      /// SearchBranches
      ///
      /// Parent Type: `BranchConnection`
      public struct SearchBranches: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchBranchesQuery.Data.SearchBranches.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }

        /// SearchBranches.Edge
        ///
        /// Parent Type: `BranchEdge`
        public struct Edge: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchEdge }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
            .field("cursor", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchBranchesQuery.Data.SearchBranches.Edge.self
          ] }

          public var node: Node { __data["node"] }
          public var cursor: String { __data["cursor"] }

          /// SearchBranches.Edge.Node
          ///
          /// Parent Type: `ScoredBranchType`
          public struct Node: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ScoredBranchType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("businessId", String.self),
              .field("name", String.self),
              .field("address", String?.self),
              .field("coordinates", Coordinates.self),
              .field("phone", String.self),
              .field("status", String?.self),
              .field("avatarUrl", String?.self),
              .field("coverUrl", String?.self),
              .field("deliveryRadius", Double?.self),
              .field("createdAt", LlegoAPI.DateTime.self),
              .field("score", Double.self),
              .field("distanceKm", Double?.self),
              .field("products", [Product].self, arguments: [
                "limit": 4,
                "availableOnly": false
              ]),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SearchBranchesQuery.Data.SearchBranches.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var businessId: String { __data["businessId"] }
            public var name: String { __data["name"] }
            public var address: String? { __data["address"] }
            public var coordinates: Coordinates { __data["coordinates"] }
            public var phone: String { __data["phone"] }
            public var status: String? { __data["status"] }
            /// Presigned URL for the branch avatar (inherits from business if not set)
            public var avatarUrl: String? { __data["avatarUrl"] }
            /// Presigned URL for the branch cover image
            public var coverUrl: String? { __data["coverUrl"] }
            public var deliveryRadius: Double? { __data["deliveryRadius"] }
            public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
            public var score: Double { __data["score"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            /// Products from this branch
            public var products: [Product] { __data["products"] }

            /// SearchBranches.Edge.Node.Coordinates
            ///
            /// Parent Type: `CoordinatesType`
            public struct Coordinates: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("type", String.self),
                .field("coordinates", [Double].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                SearchBranchesQuery.Data.SearchBranches.Edge.Node.Coordinates.self
              ] }

              public var type: String { __data["type"] }
              public var coordinates: [Double] { __data["coordinates"] }
            }

            /// SearchBranches.Edge.Node.Product
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
                .field("availability", Bool.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                SearchBranchesQuery.Data.SearchBranches.Edge.Node.Product.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var price: Double { __data["price"] }
              public var currency: String { __data["currency"] }
              /// Presigned URL for the low quality product image (100x100)
              public var imageUrlBaja: String { __data["imageUrlBaja"] }
              public var availability: Bool { __data["availability"] }
            }
          }
        }

        /// SearchBranches.PageInfo
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
            SearchBranchesQuery.Data.SearchBranches.PageInfo.self
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