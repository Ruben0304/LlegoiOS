// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RejectOrderModificationsMutation: GraphQLMutation {
    public static let operationName: String = "RejectOrderModifications"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RejectOrderModifications($orderId: String!, $jwt: String!) { rejectOrderModifications(orderId: $orderId, jwt: $jwt) { __typename id orderNumber status lastStatusAt timeline { __typename status timestamp message actor } } }"#
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
        .field("rejectOrderModifications", RejectOrderModifications.self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RejectOrderModificationsMutation.Data.self
      ] }

      /// Rechazar modificaciones y cancelar pedido
      public var rejectOrderModifications: RejectOrderModifications { __data["rejectOrderModifications"] }

      /// RejectOrderModifications
      ///
      /// Parent Type: `OrderType`
      public struct RejectOrderModifications: LlegoAPI.SelectionSet {
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
          RejectOrderModificationsMutation.Data.RejectOrderModifications.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
        public var lastStatusAt: LlegoAPI.DateTime { __data["lastStatusAt"] }
        /// Order timeline
        public var timeline: [Timeline] { __data["timeline"] }

        /// RejectOrderModifications.Timeline
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
            RejectOrderModificationsMutation.Data.RejectOrderModifications.Timeline.self
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