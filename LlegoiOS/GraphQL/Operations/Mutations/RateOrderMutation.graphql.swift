// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RateOrderMutation: GraphQLMutation {
    public static let operationName: String = "RateOrder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RateOrder($orderId: String!, $rating: Int!, $comment: String, $jwt: String!) { rateOrder(orderId: $orderId, rating: $rating, comment: $comment, jwt: $jwt) { __typename id orderNumber status } }"#
      ))

    public var orderId: String
    public var rating: Int32
    public var comment: GraphQLNullable<String>
    public var jwt: String

    public init(
      orderId: String,
      rating: Int32,
      comment: GraphQLNullable<String>,
      jwt: String
    ) {
      self.orderId = orderId
      self.rating = rating
      self.comment = comment
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "orderId": orderId,
      "rating": rating,
      "comment": comment,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("rateOrder", RateOrder.self, arguments: [
          "orderId": .variable("orderId"),
          "rating": .variable("rating"),
          "comment": .variable("comment"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RateOrderMutation.Data.self
      ] }

      /// Calificar pedido después de entrega
      public var rateOrder: RateOrder { __data["rateOrder"] }

      /// RateOrder
      ///
      /// Parent Type: `OrderType`
      public struct RateOrder: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("orderNumber", String.self),
          .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RateOrderMutation.Data.RateOrder.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
      }
    }
  }

}