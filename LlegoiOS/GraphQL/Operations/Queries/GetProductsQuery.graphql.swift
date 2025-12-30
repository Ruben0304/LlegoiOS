// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductsQuery: GraphQLQuery {
    public static let operationName: String = "GetProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProducts($branchId: String, $categoryId: String, $availableOnly: Boolean) { products( branchId: $branchId categoryId: $categoryId availableOnly: $availableOnly ) { __typename id branchId name description weight price currency image imageUrl availability categoryId createdAt } }"#
      ))

    public var branchId: GraphQLNullable<String>
    public var categoryId: GraphQLNullable<String>
    public var availableOnly: GraphQLNullable<Bool>

    public init(
      branchId: GraphQLNullable<String>,
      categoryId: GraphQLNullable<String>,
      availableOnly: GraphQLNullable<Bool>
    ) {
      self.branchId = branchId
      self.categoryId = categoryId
      self.availableOnly = availableOnly
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "branchId": branchId,
      "categoryId": categoryId,
      "availableOnly": availableOnly
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("products", [Product].self, arguments: [
          "branchId": .variable("branchId"),
          "categoryId": .variable("categoryId"),
          "availableOnly": .variable("availableOnly")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductsQuery.Data.self
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
          .field("imageUrl", String.self),
          .field("availability", Bool.self),
          .field("categoryId", String?.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductsQuery.Data.Product.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        public var image: String { __data["image"] }
        /// Presigned URL for the product image
        public var imageUrl: String { __data["imageUrl"] }
        public var availability: Bool { __data["availability"] }
        public var categoryId: String? { __data["categoryId"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}