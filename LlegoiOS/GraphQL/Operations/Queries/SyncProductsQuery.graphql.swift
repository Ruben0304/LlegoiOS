// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SyncProductsQuery: GraphQLQuery {
    public static let operationName: String = "SyncProducts"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SyncProducts($availableOnly: Boolean) { syncProducts(availableOnly: $availableOnly) { __typename id branchId name description weight price currency image imageUrl availability categoryId createdAt } }"#
      ))

    public var availableOnly: GraphQLNullable<Bool>

    public init(availableOnly: GraphQLNullable<Bool>) {
      self.availableOnly = availableOnly
    }

    @_spi(Unsafe) public var __variables: Variables? { ["availableOnly": availableOnly] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("syncProducts", [SyncProduct].self, arguments: ["availableOnly": .variable("availableOnly")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SyncProductsQuery.Data.self
      ] }

      /// Sincronizar productos (todos los productos disponibles)
      public var syncProducts: [SyncProduct] { __data["syncProducts"] }

      /// SyncProduct
      ///
      /// Parent Type: `ProductSyncType`
      public struct SyncProduct: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductSyncType }
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
          SyncProductsQuery.Data.SyncProduct.self
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