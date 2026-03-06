// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetFeedQuery: GraphQLQuery {
    public static let operationName: String = "GetFeed"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetFeed($jwt: String, $first: Int = 10, $sections: [String!], $branchTipo: String!, $productCategoryId: String) { getFeed( first: $first jwt: $jwt sections: $sections branchTipo: $branchTipo productCategoryId: $productCategoryId ) { __typename sections { __typename sectionId title description totalCount products { __typename id branchId name description price currency availability score imageUrlBaja imageUrlMedia categoryId categoryName branch { __typename id name address tipos } } } sectionDiagnostics { __typename sectionId title status reason totalBeforeDedup totalAfterDedup } timestamp } }"#
      ))

    public var jwt: GraphQLNullable<String>
    public var first: GraphQLNullable<Int32>
    public var sections: GraphQLNullable<[String]>
    public var branchTipo: String
    public var productCategoryId: GraphQLNullable<String>

    public init(
      jwt: GraphQLNullable<String>,
      first: GraphQLNullable<Int32> = 10,
      sections: GraphQLNullable<[String]>,
      branchTipo: String,
      productCategoryId: GraphQLNullable<String>
    ) {
      self.jwt = jwt
      self.first = first
      self.sections = sections
      self.branchTipo = branchTipo
      self.productCategoryId = productCategoryId
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "jwt": jwt,
      "first": first,
      "sections": sections,
      "branchTipo": branchTipo,
      "productCategoryId": productCategoryId
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("getFeed", GetFeed.self, arguments: [
          "first": .variable("first"),
          "jwt": .variable("jwt"),
          "sections": .variable("sections"),
          "branchTipo": .variable("branchTipo"),
          "productCategoryId": .variable("productCategoryId")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetFeedQuery.Data.self
      ] }

      /// Get personalized feed with multiple sections
      public var getFeed: GetFeed { __data["getFeed"] }

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
          GetFeedQuery.Data.GetFeed.self
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
            GetFeedQuery.Data.GetFeed.Section.self
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
              .field("branchId", String.self),
              .field("name", String.self),
              .field("description", String.self),
              .field("price", Double.self),
              .field("currency", String.self),
              .field("availability", Bool.self),
              .field("score", Double.self),
              .field("imageUrlBaja", String.self),
              .field("imageUrlMedia", String.self),
              .field("categoryId", String?.self),
              .field("categoryName", String?.self),
              .field("branch", Branch?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetFeedQuery.Data.GetFeed.Section.Product.self
            ] }

            public var id: String { __data["id"] }
            public var branchId: String { __data["branchId"] }
            public var name: String { __data["name"] }
            public var description: String { __data["description"] }
            public var price: Double { __data["price"] }
            public var currency: String { __data["currency"] }
            public var availability: Bool { __data["availability"] }
            public var score: Double { __data["score"] }
            /// Presigned URL for the low quality product image (100x100)
            public var imageUrlBaja: String { __data["imageUrlBaja"] }
            /// Presigned URL for the medium quality product image (500x500)
            public var imageUrlMedia: String { __data["imageUrlMedia"] }
            public var categoryId: String? { __data["categoryId"] }
            /// Product category name
            public var categoryName: String? { __data["categoryName"] }
            /// Branch associated with this product
            public var branch: Branch? { __data["branch"] }

            /// GetFeed.Section.Product.Branch
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
                .field("address", String?.self),
                .field("tipos", [GraphQLEnum<LlegoAPI.BranchTipo>].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetFeedQuery.Data.GetFeed.Section.Product.Branch.self
              ] }

              public var id: String { __data["id"] }
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
            GetFeedQuery.Data.GetFeed.SectionDiagnostic.self
          ] }

          public var sectionId: String { __data["sectionId"] }
          public var title: String { __data["title"] }
          public var status: String { __data["status"] }
          public var reason: String? { __data["reason"] }
          public var totalBeforeDedup: Int? { __data["totalBeforeDedup"] }
          public var totalAfterDedup: Int? { __data["totalAfterDedup"] }
        }
      }
    }
  }

}