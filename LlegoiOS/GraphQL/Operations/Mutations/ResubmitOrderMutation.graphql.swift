// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct ResubmitOrderMutation: GraphQLMutation {
    public static let operationName: String = "ResubmitOrder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ResubmitOrder($input: ResubmitOrderInput!, $jwt: String!) { resubmitOrder(input: $input, jwt: $jwt) { __typename id orderNumber status customerVisibleStatus deadlineAt updatedAt } }"#
      ))

    public var input: ResubmitOrderInput
    public var jwt: String

    public init(
      input: ResubmitOrderInput,
      jwt: String
    ) {
      self.input = input
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "input": input,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("resubmitOrder", ResubmitOrder.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ResubmitOrderMutation.Data.self
      ] }

      /// Editar y reenviar pedido al estado inicial
      public var resubmitOrder: ResubmitOrder { __data["resubmitOrder"] }

      /// ResubmitOrder
      ///
      /// Parent Type: `OrderType`
      public struct ResubmitOrder: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("orderNumber", String.self),
          .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
          .field("customerVisibleStatus", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
          .field("deadlineAt", LlegoAPI.DateTime?.self),
          .field("updatedAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ResubmitOrderMutation.Data.ResubmitOrder.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
        /// Customer-facing status
        public var customerVisibleStatus: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["customerVisibleStatus"] }
        public var deadlineAt: LlegoAPI.DateTime? { __data["deadlineAt"] }
        public var updatedAt: LlegoAPI.DateTime { __data["updatedAt"] }
      }
    }
  }

}