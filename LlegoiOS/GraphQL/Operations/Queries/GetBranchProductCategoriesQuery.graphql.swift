// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchProductCategoriesQuery: GraphQLQuery {
    public static let operationName: String = "GetBranchProductCategories"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranchProductCategories($branchId: String!, $onlyUsed: Boolean! = true) { branchProductCategories(branchId: $branchId, onlyUsed: $onlyUsed) { __typename id branchType name iconIos iconWeb iconAndroid createdAt } }"#
      ))

    public var branchId: String
    public var onlyUsed: Bool

    public init(
      branchId: String,
      onlyUsed: Bool = true
    ) {
      self.branchId = branchId
      self.onlyUsed = onlyUsed
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "branchId": branchId,
      "onlyUsed": onlyUsed
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("branchProductCategories", [BranchProductCategory].self, arguments: [
          "branchId": .variable("branchId"),
          "onlyUsed": .variable("onlyUsed")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchProductCategoriesQuery.Data.self
      ] }

      /// Get product categories for a branch
      public var branchProductCategories: [BranchProductCategory] { __data["branchProductCategories"] }

      /// BranchProductCategory
      ///
      /// Parent Type: `ProductCategoryType`
      public struct BranchProductCategory: LlegoAPI.SelectionSet {
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
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBranchProductCategoriesQuery.Data.BranchProductCategory.self
        ] }

        public var id: String { __data["id"] }
        public var branchType: String { __data["branchType"] }
        public var name: String { __data["name"] }
        public var iconIos: String { __data["iconIos"] }
        public var iconWeb: String { __data["iconWeb"] }
        public var iconAndroid: String { __data["iconAndroid"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}