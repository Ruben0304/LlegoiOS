// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct CancelOrderMutation: GraphQLMutation {
    public static let operationName: String = "CancelOrder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CancelOrder($orderId: String!, $reason: String, $jwt: String!) { cancelOrder(orderId: $orderId, reason: $reason, jwt: $jwt) { __typename id orderNumber status lastStatusAt timeline { __typename status timestamp message actor } } }"#
      ))

    public var orderId: String
    public var reason: GraphQLNullable<String>
    public var jwt: String

    public init(
      orderId: String,
      reason: GraphQLNullable<String>,
      jwt: String
    ) {
      self.orderId = orderId
      self.reason = reason
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "orderId": orderId,
      "reason": reason,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("cancelOrder", CancelOrder.self, arguments: [
          "orderId": .variable("orderId"),
          "reason": .variable("reason"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CancelOrderMutation.Data.self
      ] }

      /// Cancelar pedido
      public var cancelOrder: CancelOrder { __data["cancelOrder"] }

      /// CancelOrder
      ///
      /// Parent Type: `OrderType`
      public struct CancelOrder: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("orderNumber", String.self),
          .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
          .field("lastStatusAt", LlegoAPI.DateTime.self),
          .field("timeline", [Timeline].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CancelOrderMutation.Data.CancelOrder.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
        public var lastStatusAt: LlegoAPI.DateTime { __data["lastStatusAt"] }
        public var timeline: [Timeline] { __data["timeline"] }

        /// CancelOrder.Timeline
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
            CancelOrderMutation.Data.CancelOrder.Timeline.self
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