// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetCompleteFeedQuery: GraphQLQuery {
    public static let operationName: String = "GetCompleteFeed"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetCompleteFeed($jwt: String, $first: Int, $sections: [String!], $branchType: String, $branchTipo: BranchTipo, $radiusKm: Float, $categoryId: String) { getFeed(jwt: $jwt, first: $first, sections: $sections) { __typename sections { __typename sectionId title description totalCount products { __typename id name price currency imageUrl branchId branch { __typename name address tipos } categoryName availability score description } } sectionDiagnostics { __typename sectionId title status reason totalBeforeDedup totalAfterDedup } timestamp } productCategories(branchType: $branchType) { __typename id name iconIos } branches( first: 15 tipo: $branchTipo radiusKm: $radiusKm productCategoryId: $categoryId ) { __typename edges { __typename node { __typename id businessId name avatarUrl coverUrl address distanceKm } } } activeTutorials { __typename id title description videoUrl videoUrlSigned duration appTarget thumbnailUrl thumbnailUrlSigned order tags } }"#
      ))

    public var jwt: GraphQLNullable<String>
    public var first: GraphQLNullable<Int32>
    public var sections: GraphQLNullable<[String]>
    public var branchType: GraphQLNullable<String>
    public var branchTipo: GraphQLNullable<GraphQLEnum<BranchTipo>>
    public var radiusKm: GraphQLNullable<Double>
    public var categoryId: GraphQLNullable<String>

    public init(
      jwt: GraphQLNullable<String>,
      first: GraphQLNullable<Int32>,
      sections: GraphQLNullable<[String]>,
      branchType: GraphQLNullable<String>,
      branchTipo: GraphQLNullable<GraphQLEnum<BranchTipo>>,
      radiusKm: GraphQLNullable<Double>,
      categoryId: GraphQLNullable<String>
    ) {
      self.jwt = jwt
      self.first = first
      self.sections = sections
      self.branchType = branchType
      self.branchTipo = branchTipo
      self.radiusKm = radiusKm
      self.categoryId = categoryId
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "jwt": jwt,
      "first": first,
      "sections": sections,
      "branchType": branchType,
      "branchTipo": branchTipo,
      "radiusKm": radiusKm,
      "categoryId": categoryId
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("getFeed", GetFeed.self, arguments: [
          "jwt": .variable("jwt"),
          "first": .variable("first"),
          "sections": .variable("sections")
        ]),
        .field("productCategories", [ProductCategory].self, arguments: ["branchType": .variable("branchType")]),
        .field("branches", Branches.self, arguments: [
          "first": 15,
          "tipo": .variable("branchTipo"),
          "radiusKm": .variable("radiusKm"),
          "productCategoryId": .variable("categoryId")
        ]),
        .field("activeTutorials", [ActiveTutorial].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetCompleteFeedQuery.Data.self
      ] }

      /// Get personalized feed with multiple sections
      public var getFeed: GetFeed { __data["getFeed"] }
      /// Get all product categories
      public var productCategories: [ProductCategory] { __data["productCategories"] }
      /// Lista de sucursales con scoring por cercanía (paginado)
      public var branches: Branches { __data["branches"] }
      /// Get active tutorials only
      public var activeTutorials: [ActiveTutorial] { __data["activeTutorials"] }

      /// GetFeed
      ///
      /// Parent Type: `FeedResponse`
      public struct GetFeed: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FeedResponse }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("sections", [Section].self),
          .field("sectionDiagnostics", [SectionDiagnostic].self),
          .field("timestamp", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCompleteFeedQuery.Data.GetFeed.self
        ] }

        public var sections: [Section] { __data["sections"] }
        public var sectionDiagnostics: [SectionDiagnostic] { __data["sectionDiagnostics"] }
        public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }

        /// GetFeed.Section
        ///
        /// Parent Type: `FeedSection`
        public struct Section: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FeedSection }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("sectionId", String.self),
            .field("title", String.self),
            .field("description", String?.self),
            .field("totalCount", Int.self),
            .field("products", [Product].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetCompleteFeedQuery.Data.GetFeed.Section.self
          ] }

          public var sectionId: String { __data["sectionId"] }
          public var title: String { __data["title"] }
          public var description: String? { __data["description"] }
          public var totalCount: Int { __data["totalCount"] }
          public var products: [Product] { __data["products"] }

          /// GetFeed.Section.Product
          ///
          /// Parent Type: `FeedProductType`
          public struct Product: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FeedProductType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("name", String.self),
              .field("price", Double.self),
              .field("currency", String.self),
              .field("imageUrl", String.self),
              .field("branchId", String.self),
              .field("branch", Branch?.self),
              .field("categoryName", String?.self),
              .field("availability", Bool.self),
              .field("score", Double.self),
              .field("description", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetCompleteFeedQuery.Data.GetFeed.Section.Product.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            /// Presigned URL for the product image
            public var imageUrl: String { __data["imageUrl"] }
            public var branchId: String { __data["branchId"] }
            /// Branch associated with this product
            public var branch: Branch? { __data["branch"] }
            /// Product category name
            public var categoryName: String? { __data["categoryName"] }
            public var availability: Bool { __data["availability"] }
            public var score: Double { __data["score"] }
            public var description: String { __data["description"] }

            /// GetFeed.Section.Product.Branch
            ///
            /// Parent Type: `BranchType`
            public struct Branch: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("name", String.self),
                .field("address", String?.self),
                .field("tipos", [GraphQLEnum<LlegoAPI.BranchTipo>].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetCompleteFeedQuery.Data.GetFeed.Section.Product.Branch.self
              ] }

              public var name: String { __data["name"] }
              public var address: String? { __data["address"] }
              public var tipos: [GraphQLEnum<LlegoAPI.BranchTipo>] { __data["tipos"] }
            }
          }
        }

        /// GetFeed.SectionDiagnostic
        ///
        /// Parent Type: `FeedSectionDiagnostic`
        public struct SectionDiagnostic: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FeedSectionDiagnostic }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("sectionId", String.self),
            .field("title", String.self),
            .field("status", String.self),
            .field("reason", String?.self),
            .field("totalBeforeDedup", Int?.self),
            .field("totalAfterDedup", Int?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetCompleteFeedQuery.Data.GetFeed.SectionDiagnostic.self
          ] }

          public var sectionId: String { __data["sectionId"] }
          public var title: String { __data["title"] }
          public var status: String { __data["status"] }
          public var reason: String? { __data["reason"] }
          public var totalBeforeDedup: Int? { __data["totalBeforeDedup"] }
          public var totalAfterDedup: Int? { __data["totalAfterDedup"] }
        }
      }

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
          GetCompleteFeedQuery.Data.ProductCategory.self
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
          GetCompleteFeedQuery.Data.Branches.self
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
            GetCompleteFeedQuery.Data.Branches.Edge.self
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
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetCompleteFeedQuery.Data.Branches.Edge.Node.self
            ] }

            public var id: String { __data["id"] }
            public var businessId: String { __data["businessId"] }
            public var name: String { __data["name"] }
            /// Presigned URL for the branch avatar (inherits from business if not set)
            public var avatarUrl: String? { __data["avatarUrl"] }
            /// Presigned URL for the branch cover image
            public var coverUrl: String? { __data["coverUrl"] }
            public var address: String? { __data["address"] }
            /// Distance in kilometers from user
            public var distanceKm: Double? { __data["distanceKm"] }
          }
        }
      }

      /// ActiveTutorial
      ///
      /// Parent Type: `TutorialType`
      public struct ActiveTutorial: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.TutorialType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("title", String.self),
          .field("description", String.self),
          .field("videoUrl", String.self),
          .field("videoUrlSigned", String.self),
          .field("duration", Int.self),
          .field("appTarget", GraphQLEnum<LlegoAPI.AppTarget>.self),
          .field("thumbnailUrl", String?.self),
          .field("thumbnailUrlSigned", String?.self),
          .field("order", Int.self),
          .field("tags", [String].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCompleteFeedQuery.Data.ActiveTutorial.self
        ] }

        public var id: String { __data["id"] }
        public var title: String { __data["title"] }
        public var description: String { __data["description"] }
        public var videoUrl: String { __data["videoUrl"] }
        /// Presigned URL for the tutorial video
        public var videoUrlSigned: String { __data["videoUrlSigned"] }
        public var duration: Int { __data["duration"] }
        public var appTarget: GraphQLEnum<LlegoAPI.AppTarget> { __data["appTarget"] }
        public var thumbnailUrl: String? { __data["thumbnailUrl"] }
        /// Presigned URL for the tutorial thumbnail
        public var thumbnailUrlSigned: String? { __data["thumbnailUrlSigned"] }
        public var order: Int { __data["order"] }
        public var tags: [String] { __data["tags"] }
      }
    }
  }

}