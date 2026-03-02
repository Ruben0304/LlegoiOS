// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetOrderDetailQuery: GraphQLQuery {
    public static let operationName: String = "GetOrderDetail"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetOrderDetail($id: String!, $jwt: String!) { order(id: $id, jwt: $jwt) { __typename id orderNumber status subtotal deliveryFee total currency paymentMethod paymentStatus createdAt updatedAt lastStatusAt isEditable canCancel estimatedDeliveryTime estimatedMinutesRemaining items { __typename productId name price quantity imageUrl wasModifiedByStore lineTotal } discounts { __typename id title amount type } deliveryAddress { __typename street city reference addressType buildingName floor apartment deliveryInstructions coordinates { __typename type coordinates } } deliveryPerson { __typename id name phone rating vehicleType vehiclePlate profileImageUrl isOnline } timeline { __typename status timestamp message actor } comments { __typename id author message timestamp } branch { __typename id name address phone avatarUrl coordinates { __typename type coordinates } } business { __typename id name avatarUrl } } }"#
      ))

    public var id: String
    public var jwt: String

    public init(
      id: String,
      jwt: String
    ) {
      self.id = id
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("order", Order?.self, arguments: [
          "id": .variable("id"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetOrderDetailQuery.Data.self
      ] }

      /// Obtener un pedido por ID
      public var order: Order? { __data["order"] }

      /// Order
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
          .field("subtotal", Double.self),
          .field("deliveryFee", Double.self),
          .field("total", Double.self),
          .field("currency", String.self),
          .field("paymentMethod", String.self),
          .field("paymentStatus", GraphQLEnum<LlegoAPI.PaymentStatusEnum>.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("updatedAt", LlegoAPI.DateTime.self),
          .field("lastStatusAt", LlegoAPI.DateTime.self),
          .field("isEditable", Bool.self),
          .field("canCancel", Bool.self),
          .field("estimatedDeliveryTime", LlegoAPI.DateTime?.self),
          .field("estimatedMinutesRemaining", Int?.self),
          .field("items", [Item].self),
          .field("discounts", [Discount].self),
          .field("deliveryAddress", DeliveryAddress.self),
          .field("deliveryPerson", DeliveryPerson?.self),
          .field("timeline", [Timeline].self),
          .field("comments", [Comment].self),
          .field("branch", Branch.self),
          .field("business", Business.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetOrderDetailQuery.Data.Order.self
        ] }

        public var id: String { __data["id"] }
        public var orderNumber: String { __data["orderNumber"] }
        public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
        public var subtotal: Double { __data["subtotal"] }
        public var deliveryFee: Double { __data["deliveryFee"] }
        public var total: Double { __data["total"] }
        public var currency: String { __data["currency"] }
        public var paymentMethod: String { __data["paymentMethod"] }
        public var paymentStatus: GraphQLEnum<LlegoAPI.PaymentStatusEnum> { __data["paymentStatus"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var updatedAt: LlegoAPI.DateTime { __data["updatedAt"] }
        public var lastStatusAt: LlegoAPI.DateTime { __data["lastStatusAt"] }
        /// Whether order can be edited by customer
        public var isEditable: Bool { __data["isEditable"] }
        /// Whether order can be cancelled
        public var canCancel: Bool { __data["canCancel"] }
        public var estimatedDeliveryTime: LlegoAPI.DateTime? { __data["estimatedDeliveryTime"] }
        /// Estimated minutes remaining for delivery
        public var estimatedMinutesRemaining: Int? { __data["estimatedMinutesRemaining"] }
        /// Order items
        public var items: [Item] { __data["items"] }
        /// Applied discounts
        public var discounts: [Discount] { __data["discounts"] }
        /// Delivery address
        public var deliveryAddress: DeliveryAddress { __data["deliveryAddress"] }
        /// Assigned delivery person
        public var deliveryPerson: DeliveryPerson? { __data["deliveryPerson"] }
        /// Order timeline
        public var timeline: [Timeline] { __data["timeline"] }
        /// Order comments
        public var comments: [Comment] { __data["comments"] }
        /// Branch preparing the order
        public var branch: Branch { __data["branch"] }
        /// Business owning the branch
        public var business: Business { __data["business"] }

        /// Order.Item
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
            GetOrderDetailQuery.Data.Order.Item.self
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

        /// Order.Discount
        ///
        /// Parent Type: `OrderDiscountType`
        public struct Discount: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderDiscountType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("title", String.self),
            .field("amount", Double.self),
            .field("type", GraphQLEnum<LlegoAPI.DiscountTypeEnum>.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.Discount.self
          ] }

          public var id: String { __data["id"] }
          public var title: String { __data["title"] }
          public var amount: Double { __data["amount"] }
          public var type: GraphQLEnum<LlegoAPI.DiscountTypeEnum> { __data["type"] }
        }

        /// Order.DeliveryAddress
        ///
        /// Parent Type: `DeliveryAddressType`
        public struct DeliveryAddress: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.DeliveryAddressType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("street", String.self),
            .field("city", String?.self),
            .field("reference", String?.self),
            .field("addressType", GraphQLEnum<LlegoAPI.AddressTypeEnum>.self),
            .field("buildingName", String?.self),
            .field("floor", String?.self),
            .field("apartment", String?.self),
            .field("deliveryInstructions", String?.self),
            .field("coordinates", Coordinates.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.DeliveryAddress.self
          ] }

          public var street: String { __data["street"] }
          public var city: String? { __data["city"] }
          public var reference: String? { __data["reference"] }
          public var addressType: GraphQLEnum<LlegoAPI.AddressTypeEnum> { __data["addressType"] }
          public var buildingName: String? { __data["buildingName"] }
          public var floor: String? { __data["floor"] }
          public var apartment: String? { __data["apartment"] }
          public var deliveryInstructions: String? { __data["deliveryInstructions"] }
          /// Delivery coordinates
          public var coordinates: Coordinates { __data["coordinates"] }

          /// Order.DeliveryAddress.Coordinates
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
              GetOrderDetailQuery.Data.Order.DeliveryAddress.Coordinates.self
            ] }

            public var type: String { __data["type"] }
            public var coordinates: [Double] { __data["coordinates"] }
          }
        }

        /// Order.DeliveryPerson
        ///
        /// Parent Type: `DeliveryPersonType`
        public struct DeliveryPerson: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.DeliveryPersonType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("phone", String.self),
            .field("rating", Double.self),
            .field("vehicleType", GraphQLEnum<LlegoAPI.VehicleTypeEnum>.self),
            .field("vehiclePlate", String?.self),
            .field("profileImageUrl", String?.self),
            .field("isOnline", Bool.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.DeliveryPerson.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var phone: String { __data["phone"] }
          public var rating: Double { __data["rating"] }
          public var vehicleType: GraphQLEnum<LlegoAPI.VehicleTypeEnum> { __data["vehicleType"] }
          public var vehiclePlate: String? { __data["vehiclePlate"] }
          public var profileImageUrl: String? { __data["profileImageUrl"] }
          public var isOnline: Bool { __data["isOnline"] }
        }

        /// Order.Timeline
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
            GetOrderDetailQuery.Data.Order.Timeline.self
          ] }

          public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
          public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }
          public var message: String { __data["message"] }
          public var actor: GraphQLEnum<LlegoAPI.OrderActorEnum> { __data["actor"] }
        }

        /// Order.Comment
        ///
        /// Parent Type: `OrderCommentType`
        public struct Comment: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderCommentType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("author", GraphQLEnum<LlegoAPI.OrderActorEnum>.self),
            .field("message", String.self),
            .field("timestamp", LlegoAPI.DateTime.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.Comment.self
          ] }

          public var id: String { __data["id"] }
          public var author: GraphQLEnum<LlegoAPI.OrderActorEnum> { __data["author"] }
          public var message: String { __data["message"] }
          public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }
        }

        /// Order.Branch
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
            .field("address", String?.self),
            .field("phone", String.self),
            .field("avatarUrl", String?.self),
            .field("coordinates", Coordinates.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var address: String? { __data["address"] }
          public var phone: String { __data["phone"] }
          /// Presigned URL for the branch avatar (inherits from business if not set)
          public var avatarUrl: String? { __data["avatarUrl"] }
          public var coordinates: Coordinates { __data["coordinates"] }

          /// Order.Branch.Coordinates
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
              GetOrderDetailQuery.Data.Order.Branch.Coordinates.self
            ] }

            public var type: String { __data["type"] }
            public var coordinates: [Double] { __data["coordinates"] }
          }
        }

        /// Order.Business
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
            .field("avatarUrl", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderDetailQuery.Data.Order.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the business avatar
          public var avatarUrl: String? { __data["avatarUrl"] }
        }
      }
    }
  }

}