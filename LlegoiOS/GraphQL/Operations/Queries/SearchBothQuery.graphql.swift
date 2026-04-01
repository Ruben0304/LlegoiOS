// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchBothQuery: GraphQLQuery {
    public static let operationName: String = "SearchBoth"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchBoth($query: String!, $firstProducts: Int! = 10, $firstBranches: Int! = 8, $useVectorSearch: Boolean, $jwt: String) { searchProducts( query: $query first: $firstProducts useVectorSearch: $useVectorSearch jwt: $jwt ) { __typename edges { __typename node { __typename id name price currency imageUrlBaja business { __typename id name avatarUrl avatarUrlBaja avatarUrlAlta } } } } searchBranches( query: $query first: $firstBranches useVectorSearch: $useVectorSearch jwt: $jwt ) { __typename edges { __typename node { __typename id name description avatarUrl avatarUrlBaja avatarUrlAlta coverUrl coverUrlBaja coverUrlAlta address coordinates { __typename type coordinates } deliveryRadius products(limit: 4, availableOnly: false) { __typename id name price currency imageUrlBaja availability } } } } }"#
      ))

    public var query: String
    public var firstProducts: Int32
    public var firstBranches: Int32
    public var useVectorSearch: GraphQLNullable<Bool>
    public var jwt: GraphQLNullable<String>

    public init(
      query: String,
      firstProducts: Int32 = 10,
      firstBranches: Int32 = 8,
      useVectorSearch: GraphQLNullable<Bool>,
      jwt: GraphQLNullable<String>
    ) {
      self.query = query
      self.firstProducts = firstProducts
      self.firstBranches = firstBranches
      self.useVectorSearch = useVectorSearch
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "firstProducts": firstProducts,
      "firstBranches": firstBranches,
      "useVectorSearch": useVectorSearch,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchProducts", SearchProducts.self, arguments: [
          "query": .variable("query"),
          "first": .variable("firstProducts"),
          "useVectorSearch": .variable("useVectorSearch"),
          "jwt": .variable("jwt")
        ]),
        .field("searchBranches", SearchBranches.self, arguments: [
          "query": .variable("query"),
          "first": .variable("firstBranches"),
          "useVectorSearch": .variable("useVectorSearch"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchBothQuery.Data.self
      ] }

      /// Buscar productos con scoring por cercanía (paginado)
      public var searchProducts: SearchProducts { __data["searchProducts"] }
      /// Buscar sucursales con scoring por cercanía (paginado)
      public var searchBranches: SearchBranches { __data["searchBranches"] }

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
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchBothQuery.Data.SearchProducts.self
        ] }

        public var edges: [Edge] { __data["edges"] }

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
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchBothQuery.Data.SearchProducts.Edge.self
          ] }

          public var node: Node { __data["node"] }

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
              .field("name", String.self),
              .field("price", Double.self),
              .field("currency", String.self),
              .field("imageUrlBaja", String.self),
              .field("business", Business?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SearchBothQuery.Data.SearchProducts.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the low quality product image (720x540)
            public var imageUrlBaja: String { __data["imageUrlBaja"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

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
                .field("avatarUrlBaja", String?.self),
                .field("avatarUrlAlta", String?.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                SearchBothQuery.Data.SearchProducts.Edge.Node.Business.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the business avatar
              public var avatarUrl: String? { __data["avatarUrl"] }
              public var avatarUrlBaja: String? { __data["avatarUrlBaja"] }
              public var avatarUrlAlta: String? { __data["avatarUrlAlta"] }
            }
          }
        }
      }

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
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchBothQuery.Data.SearchBranches.self
        ] }

        public var edges: [Edge] { __data["edges"] }

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
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchBothQuery.Data.SearchBranches.Edge.self
          ] }

          public var node: Node { __data["node"] }

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
              .field("name", String.self),
              .field("description", String?.self),
              .field("avatarUrl", String?.self),
              .field("avatarUrlBaja", String?.self),
              .field("avatarUrlAlta", String?.self),
              .field("coverUrl", String?.self),
              .field("coverUrlBaja", String?.self),
              .field("coverUrlAlta", String?.self),
              .field("address", String?.self),
              .field("coordinates", Coordinates.self),
              .field("deliveryRadius", Double?.self),
              .field("products", [Product].self, arguments: [
                "limit": 4,
                "availableOnly": false
              ]),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SearchBothQuery.Data.SearchBranches.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var description: String? { __data["description"] }
            /// Presigned URL for the branch avatar (inherits from business if not set)
            public var avatarUrl: String? { __data["avatarUrl"] }
            public var avatarUrlBaja: String? { __data["avatarUrlBaja"] }
            public var avatarUrlAlta: String? { __data["avatarUrlAlta"] }
            /// Presigned URL for the branch cover image
            public var coverUrl: String? { __data["coverUrl"] }
            public var coverUrlBaja: String? { __data["coverUrlBaja"] }
            public var coverUrlAlta: String? { __data["coverUrlAlta"] }
            public var address: String? { __data["address"] }
            public var coordinates: Coordinates { __data["coordinates"] }
            public var deliveryRadius: Double? { __data["deliveryRadius"] }
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
                SearchBothQuery.Data.SearchBranches.Edge.Node.Coordinates.self
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
                SearchBothQuery.Data.SearchBranches.Edge.Node.Product.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
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

}
