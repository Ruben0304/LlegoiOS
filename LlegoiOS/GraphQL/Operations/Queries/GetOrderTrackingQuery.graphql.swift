// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetOrderTrackingQuery: GraphQLQuery {
    public static let operationName: String = "GetOrderTracking"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetOrderTracking($orderId: String!, $jwt: String!) { orderTracking(orderId: $orderId, jwt: $jwt) { __typename order { __typename id orderNumber status total currency estimatedDeliveryTime estimatedMinutesRemaining items { __typename productId name quantity price imageUrl } deliveryPerson { __typename id name phone rating vehicleType vehiclePlate profileImageUrl currentLocation { __typename type coordinates } isOnline } timeline { __typename status timestamp message actor } branch { __typename id name avatarUrl } } deliveryPersonLocation { __typename type coordinates } storeLocation { __typename type coordinates } deliveryLocation { __typename type coordinates } estimatedMinutes distanceKm routePolyline } }"#
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

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("orderTracking", OrderTracking?.self, arguments: [
          "orderId": .variable("orderId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetOrderTrackingQuery.Data.self
      ] }

      /// Tracking completo de un pedido
      public var orderTracking: OrderTracking? { __data["orderTracking"] }

      /// OrderTracking
      ///
      /// Parent Type: `OrderTrackingType`
      public struct OrderTracking: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderTrackingType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("order", Order.self),
          .field("deliveryPersonLocation", DeliveryPersonLocation?.self),
          .field("storeLocation", StoreLocation.self),
          .field("deliveryLocation", DeliveryLocation.self),
          .field("estimatedMinutes", Int?.self),
          .field("distanceKm", Double?.self),
          .field("routePolyline", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetOrderTrackingQuery.Data.OrderTracking.self
        ] }

        public var order: Order { __data["order"] }
        public var deliveryPersonLocation: DeliveryPersonLocation? { __data["deliveryPersonLocation"] }
        public var storeLocation: StoreLocation { __data["storeLocation"] }
        public var deliveryLocation: DeliveryLocation { __data["deliveryLocation"] }
        public var estimatedMinutes: Int? { __data["estimatedMinutes"] }
        public var distanceKm: Double? { __data["distanceKm"] }
        public var routePolyline: String? { __data["routePolyline"] }

        /// OrderTracking.Order
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
            .field("estimatedDeliveryTime", LlegoAPI.DateTime?.self),
            .field("estimatedMinutesRemaining", Int?.self),
            .field("items", [Item].self),
            .field("deliveryPerson", DeliveryPerson?.self),
            .field("timeline", [Timeline].self),
            .field("branch", Branch.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderTrackingQuery.Data.OrderTracking.Order.self
          ] }

          public var id: String { __data["id"] }
          public var orderNumber: String { __data["orderNumber"] }
          public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
          public var total: Double { __data["total"] }
          public var currency: String { __data["currency"] }
          public var estimatedDeliveryTime: LlegoAPI.DateTime? { __data["estimatedDeliveryTime"] }
          /// Estimated minutes remaining for delivery
          public var estimatedMinutesRemaining: Int? { __data["estimatedMinutesRemaining"] }
          /// Order items
          public var items: [Item] { __data["items"] }
          /// Assigned delivery person
          public var deliveryPerson: DeliveryPerson? { __data["deliveryPerson"] }
          /// Order timeline
          public var timeline: [Timeline] { __data["timeline"] }
          /// Branch preparing the order
          public var branch: Branch { __data["branch"] }

          /// OrderTracking.Order.Item
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
              .field("price", Double.self),
              .field("imageUrl", String?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetOrderTrackingQuery.Data.OrderTracking.Order.Item.self
            ] }

            public var productId: String { __data["productId"] }
            public var name: String { __data["name"] }
            public var quantity: Int { __data["quantity"] }
            public var price: Double { __data["price"] }
            /// Presigned URL for the item image
            public var imageUrl: String? { __data["imageUrl"] }
          }

          /// OrderTracking.Order.DeliveryPerson
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
              .field("currentLocation", CurrentLocation?.self),
              .field("isOnline", Bool.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetOrderTrackingQuery.Data.OrderTracking.Order.DeliveryPerson.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var phone: String { __data["phone"] }
            public var rating: Double { __data["rating"] }
            public var vehicleType: GraphQLEnum<LlegoAPI.VehicleTypeEnum> { __data["vehicleType"] }
            public var vehiclePlate: String? { __data["vehiclePlate"] }
            public var profileImageUrl: String? { __data["profileImageUrl"] }
            /// Current location of delivery person
            public var currentLocation: CurrentLocation? { __data["currentLocation"] }
            public var isOnline: Bool { __data["isOnline"] }

            /// OrderTracking.Order.DeliveryPerson.CurrentLocation
            ///
            /// Parent Type: `CoordinatesType`
            public struct CurrentLocation: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("type", String.self),
                .field("coordinates", [Double].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                GetOrderTrackingQuery.Data.OrderTracking.Order.DeliveryPerson.CurrentLocation.self
              ] }

              public var type: String { __data["type"] }
              public var coordinates: [Double] { __data["coordinates"] }
            }
          }

          /// OrderTracking.Order.Timeline
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
              GetOrderTrackingQuery.Data.OrderTracking.Order.Timeline.self
            ] }

            public var status: GraphQLEnum<LlegoAPI.OrderStatusEnum> { __data["status"] }
            public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }
            public var message: String { __data["message"] }
            public var actor: GraphQLEnum<LlegoAPI.OrderActorEnum> { __data["actor"] }
          }

          /// OrderTracking.Order.Branch
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
              GetOrderTrackingQuery.Data.OrderTracking.Order.Branch.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            /// Presigned URL for the branch avatar (inherits from business if not set)
            public var avatarUrl: String? { __data["avatarUrl"] }
          }
        }

        /// OrderTracking.DeliveryPersonLocation
        ///
        /// Parent Type: `CoordinatesType`
        public struct DeliveryPersonLocation: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("coordinates", [Double].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderTrackingQuery.Data.OrderTracking.DeliveryPersonLocation.self
          ] }

          public var type: String { __data["type"] }
          public var coordinates: [Double] { __data["coordinates"] }
        }

        /// OrderTracking.StoreLocation
        ///
        /// Parent Type: `CoordinatesType`
        public struct StoreLocation: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("coordinates", [Double].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderTrackingQuery.Data.OrderTracking.StoreLocation.self
          ] }

          public var type: String { __data["type"] }
          public var coordinates: [Double] { __data["coordinates"] }
        }

        /// OrderTracking.DeliveryLocation
        ///
        /// Parent Type: `CoordinatesType`
        public struct DeliveryLocation: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("coordinates", [Double].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetOrderTrackingQuery.Data.OrderTracking.DeliveryLocation.self
          ] }

          public var type: String { __data["type"] }
          public var coordinates: [Double] { __data["coordinates"] }
        }
      }
    }
  }

}