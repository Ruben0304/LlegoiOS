// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchProductsQuery: GraphQLQuery {
    public static let operationName: String = "SearchProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchProducts($query: String!, $limit: Int, $useVectorSearch: Boolean) { searchProducts(query: $query, limit: $limit, useVectorSearch: $useVectorSearch) { __typename id branchId name description weight price currency imageUrl availability createdAt business { __typename id name } } }"#
      ))

    public var query: String
    public var limit: GraphQLNullable<Int32>
    public var useVectorSearch: GraphQLNullable<Bool>

    public init(
      query: String,
      limit: GraphQLNullable<Int32>,
      useVectorSearch: GraphQLNullable<Bool>
    ) {
      self.query = query
      self.limit = limit
      self.useVectorSearch = useVectorSearch
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "limit": limit,
      "useVectorSearch": useVectorSearch
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchProducts", [SearchProduct].self, arguments: [
          "query": .variable("query"),
          "limit": .variable("limit"),
          "useVectorSearch": .variable("useVectorSearch")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchProductsQuery.Data.self
      ] }

      /// Buscar productos
      public var searchProducts: [SearchProduct] { __data["searchProducts"] }

      /// SearchProduct
      ///
      /// Parent Type: `ProductType`
      public struct SearchProduct: LlegoAPI.SelectionSet {
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
          .field("imageUrl", String.self),
          .field("availability", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("business", Business?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchProductsQuery.Data.SearchProduct.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Presigned URL for the product image
        public var imageUrl: String { __data["imageUrl"] }
        public var availability: Bool { __data["availability"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Business associated with this product (through branch)
        public var business: Business? { __data["business"] }

        /// SearchProduct.Business
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
            SearchProductsQuery.Data.SearchProduct.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }

}