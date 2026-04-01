// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchDetailQuery: GraphQLQuery {
    public static let operationName: String = "GetBranchDetail"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranchDetail($id: String!) { branch(id: $id) { __typename id businessId name acceptsQvapay acceptsZelle qvapayUsername zelleEmail address coordinates { __typename type coordinates } phone status avatarUrl avatarUrlBaja avatarUrlAlta coverUrl coverUrlBaja coverUrlAlta deliveryRadius acceptedCurrency exchangeRate createdAt showcases(activeOnly: true) { __typename id title description imageUrl isActive createdAt items { __typename id name description price availability } } } }"#
      ))

    public var id: String

    public init(id: String) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("branch", Branch?.self, arguments: ["id": .variable("id")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchDetailQuery.Data.self
      ] }

      /// Obtener sucursal por ID
      public var branch: Branch? { __data["branch"] }

      /// Branch
      ///
      /// Parent Type: `BranchType`
      public struct Branch: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("businessId", String.self),
          .field("name", String.self),
          .field("acceptsQvapay", Bool.self),
          .field("acceptsZelle", Bool.self),
          .field("qvapayUsername", String?.self),
          .field("zelleEmail", String?.self),
          .field("address", String?.self),
          .field("coordinates", Coordinates.self),
          .field("phone", String.self),
          .field("status", String?.self),
          .field("avatarUrl", String?.self),
          .field("avatarUrlBaja", String?.self),
          .field("avatarUrlAlta", String?.self),
          .field("coverUrl", String?.self),
          .field("coverUrlBaja", String?.self),
          .field("coverUrlAlta", String?.self),
          .field("deliveryRadius", Double?.self),
          .field("acceptedCurrency", GraphQLEnum<LlegoAPI.AcceptedCurrency>?.self),
          .field("exchangeRate", Int?.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("showcases", [Showcase].self, arguments: ["activeOnly": true]),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBranchDetailQuery.Data.Branch.self
        ] }

        public var id: String { __data["id"] }
        public var businessId: String { __data["businessId"] }
        public var name: String { __data["name"] }
        public var acceptsQvapay: Bool { __data["acceptsQvapay"] }
        public var acceptsZelle: Bool { __data["acceptsZelle"] }
        public var qvapayUsername: String? { __data["qvapayUsername"] }
        public var zelleEmail: String? { __data["zelleEmail"] }
        public var address: String? { __data["address"] }
        public var coordinates: Coordinates { __data["coordinates"] }
        public var phone: String { __data["phone"] }
        public var status: String? { __data["status"] }
        /// Presigned URL for the branch avatar (inherits from business if not set)
        public var avatarUrl: String? { __data["avatarUrl"] }
        public var avatarUrlBaja: String? { __data["avatarUrlBaja"] }
        public var avatarUrlAlta: String? { __data["avatarUrlAlta"] }
        /// Presigned URL for the branch cover image
        public var coverUrl: String? { __data["coverUrl"] }
        public var coverUrlBaja: String? { __data["coverUrlBaja"] }
        public var coverUrlAlta: String? { __data["coverUrlAlta"] }
        public var deliveryRadius: Double? { __data["deliveryRadius"] }
        public var acceptedCurrency: GraphQLEnum<LlegoAPI.AcceptedCurrency>? { __data["acceptedCurrency"] }
        public var exchangeRate: Int? { __data["exchangeRate"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Showcases from this branch
        public var showcases: [Showcase] { __data["showcases"] }

        /// Branch.Coordinates
        ///
        /// Parent Type: `CoordinatesType`
        public struct Coordinates: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("coordinates", [Double].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBranchDetailQuery.Data.Branch.Coordinates.self
          ] }

          public var type: String { __data["type"] }
          public var coordinates: [Double] { __data["coordinates"] }
        }

        /// Branch.Showcase
        ///
        /// Parent Type: `ShowcaseType`
        public struct Showcase: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ShowcaseType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("title", String.self),
            .field("description", String?.self),
            .field("imageUrl", String.self),
            .field("isActive", Bool.self),
            .field("createdAt", LlegoAPI.DateTime.self),
            .field("items", [Item]?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBranchDetailQuery.Data.Branch.Showcase.self
          ] }

          public var id: String { __data["id"] }
          public var title: String { __data["title"] }
          public var description: String? { __data["description"] }
          /// Presigned URL for the showcase image
          public var imageUrl: String { __data["imageUrl"] }
          public var isActive: Bool { __data["isActive"] }
          public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
          public var items: [Item]? { __data["items"] }

          /// Branch.Showcase.Item
          ///
          /// Parent Type: `ShowcaseItemType`
          public struct Item: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ShowcaseItemType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("name", String.self),
              .field("description", String?.self),
              .field("price", Double?.self),
              .field("availability", Bool.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetBranchDetailQuery.Data.Branch.Showcase.Item.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var description: String? { __data["description"] }
            public var price: Double? { __data["price"] }
            public var availability: Bool { __data["availability"] }
          }
        }
      }
    }
  }

}
