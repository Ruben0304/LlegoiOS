// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetCartProductsQuery: GraphQLQuery {
    public static let operationName: String = "GetCartProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetCartProducts($ids: [String!]!) { products(ids: $ids) { __typename id branchId name description weight price currency image availability createdAt } }"#
      ))

    public var ids: [String]

    public init(ids: [String]) {
      self.ids = ids
    }

    @_spi(Unsafe) public var __variables: Variables? { ["ids": ids] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("products", [Product].self, arguments: ["ids": .variable("ids")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetCartProductsQuery.Data.self
      ] }

      /// Lista de productos
      public var products: [Product] { __data["products"] }

      /// Product
      ///
      /// Parent Type: `ProductType`
      public struct Product: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("branchId", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("weight", String.self),
          .field("price", Double.self),
          .field("currency", String.self),
          .field("image", String.self),
          .field("availability", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetCartProductsQuery.Data.Product.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        public var image: String { __data["image"] }
        public var availability: Bool { __data["availability"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}