// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductsQuery: GraphQLQuery {
    public static let operationName: String = "GetProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProducts($branchId: String, $categoryId: String, $availableOnly: Boolean) { products( branchId: $branchId categoryId: $categoryId availableOnly: $availableOnly ) { __typename id branchId name price currency imageUrl availability createdAt business { __typename id name } } }"#
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
          .field("price", Double.self),
          .field("currency", String.self),
          .field("imageUrl", String.self),
          .field("availability", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("business", Business?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductsQuery.Data.Product.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Presigned URL for the product image
        public var imageUrl: String { __data["imageUrl"] }
        public var availability: Bool { __data["availability"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Business associated with this product (through branch)
        public var business: Business? { __data["business"] }

        /// Product.Business
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
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductsQuery.Data.Product.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }

}