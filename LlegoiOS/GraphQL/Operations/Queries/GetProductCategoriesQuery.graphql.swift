// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductCategoriesQuery: GraphQLQuery {
    public static let operationName: String = "GetProductCategories"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProductCategories($branchType: String) { productCategories(branchType: $branchType) { __typename id branchType name iconIos iconWeb iconAndroid createdAt } }"#
      ))

    public var branchType: GraphQLNullable<String>

    public init(branchType: GraphQLNullable<String>) {
      self.branchType = branchType
    }

    @_spi(Unsafe) public var __variables: Variables? { ["branchType": branchType] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("productCategories", [ProductCategory].self, arguments: ["branchType": .variable("branchType")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductCategoriesQuery.Data.self
      ] }

      /// Get all product categories
      public var productCategories: [ProductCategory] { __data["productCategories"] }

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
          .field("branchType", String.self),
          .field("name", String.self),
          .field("iconIos", String.self),
          .field("iconWeb", String.self),
          .field("iconAndroid", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductCategoriesQuery.Data.ProductCategory.self
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