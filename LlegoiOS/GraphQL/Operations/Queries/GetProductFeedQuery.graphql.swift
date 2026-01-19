// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductFeedQuery: GraphQLQuery {
    public static let operationName: String = "GetProductFeed"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProductFeed($branchTipo: String, $radiusKm: Float, $jwt: String) { productCategories(branchType: $branchTipo) { __typename id name iconIos } branches(first: 15, radiusKm: $radiusKm, jwt: $jwt) { __typename edges { __typename node { __typename id businessId name avatarUrl coverUrl address distanceKm status } } } featuredProducts: products( first: 6 radiusKm: $radiusKm availableOnly: true jwt: $jwt ) { __typename edges { __typename node { __typename id name price currency imageUrl distanceKm branch { __typename id name avatarUrl } business { __typename name } } } } recentProducts: products( first: 10 radiusKm: $radiusKm availableOnly: true jwt: $jwt ) { __typename edges { __typename node { __typename id name price currency imageUrl distanceKm branch { __typename id name avatarUrl } business { __typename name } } } pageInfo { __typename hasNextPage endCursor } } popularProducts: products( first: 8 radiusKm: $radiusKm availableOnly: true jwt: $jwt ) { __typename edges { __typename node { __typename id name price currency imageUrl distanceKm branch { __typename id name avatarUrl } business { __typename name } } } } }"#
      ))

    public var branchTipo: GraphQLNullable<String>
    public var radiusKm: GraphQLNullable<Double>
    public var jwt: GraphQLNullable<String>

    public init(
      branchTipo: GraphQLNullable<String>,
      radiusKm: GraphQLNullable<Double>,
      jwt: GraphQLNullable<String>
    ) {
      self.branchTipo = branchTipo
      self.radiusKm = radiusKm
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "branchTipo": branchTipo,
      "radiusKm": radiusKm,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("productCategories", [ProductCategory].self, arguments: ["branchType": .variable("branchTipo")]),
        .field("branches", Branches.self, arguments: [
          "first": 15,
          "radiusKm": .variable("radiusKm"),
          "jwt": .variable("jwt")
        ]),
        .field("products", alias: "featuredProducts", FeaturedProducts.self, arguments: [
          "first": 6,
          "radiusKm": .variable("radiusKm"),
          "availableOnly": true,
          "jwt": .variable("jwt")
        ]),
        .field("products", alias: "recentProducts", RecentProducts.self, arguments: [
          "first": 10,
          "radiusKm": .variable("radiusKm"),
          "availableOnly": true,
          "jwt": .variable("jwt")
        ]),
        .field("products", alias: "popularProducts", PopularProducts.self, arguments: [
          "first": 8,
          "radiusKm": .variable("radiusKm"),
          "availableOnly": true,
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductFeedQuery.Data.self
      ] }

      /// Get all product categories
      public var productCategories: [ProductCategory] { __data["productCategories"] }
      /// Lista de sucursales con scoring por cercanía (paginado)
      public var branches: Branches { __data["branches"] }
      /// Lista de productos con scoring por cercanía (paginado)
      public var featuredProducts: FeaturedProducts { __data["featuredProducts"] }
      /// Lista de productos con scoring por cercanía (paginado)
      public var recentProducts: RecentProducts { __data["recentProducts"] }
      /// Lista de productos con scoring por cercanía (paginado)
      public var popularProducts: PopularProducts { __data["popularProducts"] }

      /// ProductCategory
      ///
      /// Parent Type: `ProductCategoryType`
      public struct ProductCategory: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductCategoryType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("iconIos", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductFeedQuery.Data.ProductCategory.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var iconIos: String { __data["iconIos"] }
      }

      /// Branches
      ///
      /// Parent Type: `BranchConnection`
      public struct Branches: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductFeedQuery.Data.Branches.self
        ] }

        public var edges: [Edge] { __data["edges"] }

        /// Branches.Edge
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
            GetProductFeedQuery.Data.Branches.Edge.self
          ] }

          public var node: Node { __data["node"] }

          /// Branches.Edge.Node
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
              .field("avatarUrl", String?.self),
              .field("coverUrl", String?.self),
              .field("address", String?.self),
              .field("distanceKm", Double?.self),
              .field("status", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductFeedQuery.Data.Branches.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var businessId: String { __data["businessId"] }
            public var name: String { __data["name"] }
            /// Presigned URL for the branch avatar
            public var avatarUrl: String? { __data["avatarUrl"] }
            /// Presigned URL for the branch cover image
            public var coverUrl: String? { __data["coverUrl"] }
            public var address: String? { __data["address"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            public var status: String { __data["status"] }
          }
        }
      }

      /// FeaturedProducts
      ///
      /// Parent Type: `ProductConnection`
      public struct FeaturedProducts: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductFeedQuery.Data.FeaturedProducts.self
        ] }

        public var edges: [Edge] { __data["edges"] }

        /// FeaturedProducts.Edge
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
            GetProductFeedQuery.Data.FeaturedProducts.Edge.self
          ] }

          public var node: Node { __data["node"] }

          /// FeaturedProducts.Edge.Node
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
              .field("imageUrl", String.self),
              .field("distanceKm", Double?.self),
              .field("branch", Branch?.self),
              .field("business", Business?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductFeedQuery.Data.FeaturedProducts.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            /// Branch associated with this product
            public var branch: Branch? { __data["branch"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

            /// FeaturedProducts.Edge.Node.Branch
            ///
            /// Parent Type: `BranchType`
            public struct Branch: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("name", String.self),
                .field("avatarUrl", String?.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetProductFeedQuery.Data.FeaturedProducts.Edge.Node.Branch.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the branch avatar
              public var avatarUrl: String? { __data["avatarUrl"] }
            }

            /// FeaturedProducts.Edge.Node.Business
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
                GetProductFeedQuery.Data.FeaturedProducts.Edge.Node.Business.self
              ] }

              public var name: String { __data["name"] }
            }
          }
        }
      }

      /// RecentProducts
      ///
      /// Parent Type: `ProductConnection`
      public struct RecentProducts: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductFeedQuery.Data.RecentProducts.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }

        /// RecentProducts.Edge
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
            GetProductFeedQuery.Data.RecentProducts.Edge.self
          ] }

          public var node: Node { __data["node"] }

          /// RecentProducts.Edge.Node
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
              .field("imageUrl", String.self),
              .field("distanceKm", Double?.self),
              .field("branch", Branch?.self),
              .field("business", Business?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductFeedQuery.Data.RecentProducts.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            /// Branch associated with this product
            public var branch: Branch? { __data["branch"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

            /// RecentProducts.Edge.Node.Branch
            ///
            /// Parent Type: `BranchType`
            public struct Branch: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("name", String.self),
                .field("avatarUrl", String?.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetProductFeedQuery.Data.RecentProducts.Edge.Node.Branch.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the branch avatar
              public var avatarUrl: String? { __data["avatarUrl"] }
            }

            /// RecentProducts.Edge.Node.Business
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
                GetProductFeedQuery.Data.RecentProducts.Edge.Node.Business.self
              ] }

              public var name: String { __data["name"] }
            }
          }
        }

        /// RecentProducts.PageInfo
        ///
        /// Parent Type: `PageInfo`
        public struct PageInfo: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PageInfo }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("hasNextPage", Bool.self),
            .field("endCursor", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductFeedQuery.Data.RecentProducts.PageInfo.self
          ] }

          public var hasNextPage: Bool { __data["hasNextPage"] }
          public var endCursor: String? { __data["endCursor"] }
        }
      }

      /// PopularProducts
      ///
      /// Parent Type: `ProductConnection`
      public struct PopularProducts: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductConnection }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductFeedQuery.Data.PopularProducts.self
        ] }

        public var edges: [Edge] { __data["edges"] }

        /// PopularProducts.Edge
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
            GetProductFeedQuery.Data.PopularProducts.Edge.self
          ] }

          public var node: Node { __data["node"] }

          /// PopularProducts.Edge.Node
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
              .field("imageUrl", String.self),
              .field("distanceKm", Double?.self),
              .field("branch", Branch?.self),
              .field("business", Business?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductFeedQuery.Data.PopularProducts.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
            /// Branch associated with this product
            public var branch: Branch? { __data["branch"] }
            /// Business associated with this product (through branch)
            public var business: Business? { __data["business"] }

            /// PopularProducts.Edge.Node.Branch
            ///
            /// Parent Type: `BranchType`
            public struct Branch: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("name", String.self),
                .field("avatarUrl", String?.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetProductFeedQuery.Data.PopularProducts.Edge.Node.Branch.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              /// Presigned URL for the branch avatar
              public var avatarUrl: String? { __data["avatarUrl"] }
            }

            /// PopularProducts.Edge.Node.Business
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
                GetProductFeedQuery.Data.PopularProducts.Edge.Node.Business.self
              ] }

              public var name: String { __data["name"] }
            }
          }
        }
      }
    }
  }

}