// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetMyOrdersQuery: GraphQLQuery {
    public static let operationName: String = "GetMyOrders"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetMyOrders($status: OrderStatusEnum, $limit: Int, $offset: Int, $jwt: String!) { myOrders(status: $status, limit: $limit, offset: $offset, jwt: $jwt) { __typename orders { __typename id orderNumber status total currency paymentStatus createdAt lastStatusAt estimatedMinutesRemaining items { __typename productId name quantity imageUrl } branch { __typename id name avatarUrl } business { __typename id name } } totalCount hasMore } }"#
      ))

    public var status: GraphQLNullable<GraphQLEnum<OrderStatusEnum>>
    public var limit: GraphQLNullable<Int32>
    public var offset: GraphQLNullable<Int32>
    public var jwt: String

    public init(
      status: GraphQLNullable<GraphQLEnum<OrderStatusEnum>>,
      limit: GraphQLNullable<Int32>,
      offset: GraphQLNullable<Int32>,
      jwt: String
    ) {
      self.status = status
      self.limit = limit
      self.offset = offset
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "status": status,
      "limit": limit,
      "offset": offset,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("myOrders", MyOrders.self, arguments: [
          "status": .variable("status"),
          "limit": .variable("limit"),
          "offset": .variable("offset"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetMyOrdersQuery.Data.self
      ] }

      /// Obtener mis pedidos con paginación
      public var myOrders: MyOrders { __data["myOrders"] }

      /// MyOrders
      ///
      /// Parent Type: `OrdersConnectionType`
      public struct MyOrders: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrdersConnectionType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("orders", [Order].self),
          .field("totalCount", Int.self),
          .field("hasMore", Bool.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetMyOrdersQuery.Data.MyOrders.self
        ] }

        public var orders: [Order] { __data["orders"] }
        public var totalCount: Int { __data["totalCount"] }
        public var hasMore: Bool { __data["hasMore"] }

        /// MyOrders.Order
        ///
        /// Parent Type: `OrderType`
        public struct Order: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("orderNumber", String.self),
            .field("status", GraphQLEnum<LlegoAPI.OrderStatusEnum>.self),
            .field("total", Double.self),
            .field("currency", String.self),
            .field("paymentStatus", GraphQLEnum<LlegoAPI.PaymentStatusEnum>.self),
            .field("createdAt", LlegoAPI.DateTime.self),
            .field("lastStatusAt", LlegoAPI.DateTime.self),
            .field("estimatedMinutesRemaining", Int?.self),
            .field("items", [Item].self),
            .field("branch", Branch.self),
            .field("business", Business.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetMyOrdersQuery.Data.MyOrders.Order.self
          ] }

          public var id: String { __data["id"] }
          public var orderNumber: String { __data["orderNumber"] }
          public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
          public var total: Double { __data["total"] }
          public var currency: String { __data["currency"] }
          public var paymentStatus: GraphQLEnum<LlegoAPI.PaymentStatusEnum> { __data["paymentStatus"] }
          public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
          public var lastStatusAt: LlegoAPI.DateTime { __data["lastStatusAt"] }
          /// Estimated minutes remaining for delivery
          public var estimatedMinutesRemaining: Int? { __data["estimatedMinutesRemaining"] }
          /// Order items
          public var items: [Item] { __data["items"] }
          /// Branch preparing the order
          public var branch: Branch { __data["branch"] }
          /// Business owning the branch
          public var business: Business { __data["business"] }

          /// MyOrders.Order.Item
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
              .field("quantity", Int.self),
              .field("imageUrl", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMyOrdersQuery.Data.MyOrders.Order.Item.self
            ] }

            public var productId: String { __data["productId"] }
            public var name: String { __data["name"] }
            public var quantity: Int { __data["quantity"] }
            public var imageUrl: String { __data["imageUrl"] }
          }

          /// MyOrders.Order.Branch
          ///
          /// Parent Type: `BranchType`
          public struct Branch: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("name", String.self),
              .field("avatarUrl", String?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetMyOrdersQuery.Data.MyOrders.Order.Branch.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            /// Presigned URL for the branch avatar
            public var avatarUrl: String? { __data["avatarUrl"] }
          }

          /// MyOrders.Order.Business
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
              GetMyOrdersQuery.Data.MyOrders.Order.Business.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
          }
        }
      }
    }
  }

}