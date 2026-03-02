// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AcceptOrderModificationsMutation: GraphQLMutation {
    public static let operationName: String = "AcceptOrderModifications"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AcceptOrderModifications($orderId: String!, $jwt: String!) { acceptOrderModifications(orderId: $orderId, jwt: $jwt) { __typename id orderNumber status subtotal total lastStatusAt items { __typename productId name price quantity imageUrl wasModifiedByStore lineTotal } timeline { __typename status timestamp message actor } } }"#
      ))

    public var orderId: String
    public var jwt: String

    public init(
      orderId: String,
      jwt: String
    ) {
      self.orderId = orderId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "orderId": orderId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("acceptOrderModifications", AcceptOrderModifications.self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AcceptOrderModificationsMutation.Data.self
      ] }

      /// Aceptar modificaciones de la tienda
      public var acceptOrderModifications: AcceptOrderModifications { __data["acceptOrderModifications"] }

      /// AcceptOrderModifications
      ///
      /// Parent Type: `OrderType`
      public struct AcceptOrderModifications: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("orderNumber", String.self),
          .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
          .field("subtotal", Double.self),
          .field("total", Double.self),
          .field("lastStatusAt", LlegoAPI.DateTime.self),
          .field("items", [Item].self),
          .field("timeline", [Timeline].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AcceptOrderModificationsMutation.Data.AcceptOrderModifications.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
        public var subtotal: Double { __data["subtotal"] }
        public var total: Double { __data["total"] }
        public var lastStatusAt: LlegoAPI.DateTime { __data["lastStatusAt"] }
        /// Order items
        public var items: [Item] { __data["items"] }
        /// Order timeline
        public var timeline: [Timeline] { __data["timeline"] }

        /// AcceptOrderModifications.Item
        ///
        /// Parent Type: `OrderItemType`
        public struct Item: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderItemType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("productId", String.self),
            .field("name", String.self),
            .field("price", Double.self),
            .field("quantity", Int.self),
            .field("imageUrl", String?.self),
            .field("wasModifiedByStore", Bool.self),
            .field("lineTotal", Double.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AcceptOrderModificationsMutation.Data.AcceptOrderModifications.Item.self
          ] }

          public var productId: String { __data["productId"] }
          public var name: String { __data["name"] }
          public var price: Double { __data["price"] }
          public var quantity: Int { __data["quantity"] }
          public var imageUrl: String? { __data["imageUrl"] }
          public var wasModifiedByStore: Bool { __data["wasModifiedByStore"] }
          /// Line total (price * quantity)
          public var lineTotal: Double { __data["lineTotal"] }
        }

        /// AcceptOrderModifications.Timeline
        ///
        /// Parent Type: `OrderTimelineType`
        public struct Timeline: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderTimelineType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
            .field("timestamp", LlegoAPI.DateTime.self),
            .field("message", String.self),
            .field("actor", GraphQLEnum<LlegoAPI.OrderActorEnum>.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AcceptOrderModificationsMutation.Data.AcceptOrderModifications.Timeline.self
          ] }

          public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
          public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }
          public var message: String { __data["message"] }
          public var actor: GraphQLEnum<LlegoAPI.OrderActorEnum> { __data["actor"] }
        }
      }
    }
  }

}