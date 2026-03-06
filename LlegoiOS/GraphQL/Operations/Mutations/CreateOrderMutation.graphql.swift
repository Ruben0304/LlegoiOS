// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct CreateOrderMutation: GraphQLMutation {
    public static let operationName: String = "CreateOrder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateOrder($input: CreateOrderInput!, $jwt: String!) { createOrder(input: $input, jwt: $jwt) { __typename id orderNumber status subtotal deliveryFee total currency paymentMethod paymentStatus createdAt items { __typename productId name price quantity imageUrl lineTotal } discounts { __typename id title amount type } deliveryAddress { __typename street city reference addressType buildingName floor apartment deliveryInstructions } branch { __typename id name avatarUrl } business { __typename id name } } }"#
      ))

    public var input: CreateOrderInput
    public var jwt: String

    public init(
      input: CreateOrderInput,
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
        .field("createOrder", CreateOrder.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CreateOrderMutation.Data.self
      ] }

      /// Crear nuevo pedido
      public var createOrder: CreateOrder { __data["createOrder"] }

      /// CreateOrder
      ///
      /// Parent Type: `OrderType`
      public struct CreateOrder: LlegoAPI.SelectionSet {
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
          .field("items", [Item].self),
          .field("discounts", [Discount].self),
          .field("deliveryAddress", DeliveryAddress.self),
          .field("branch", Branch.self),
          .field("business", Business.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CreateOrderMutation.Data.CreateOrder.self
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
        /// Order items
        public var items: [Item] { __data["items"] }
        /// Applied discounts
        public var discounts: [Discount] { __data["discounts"] }
        /// Delivery address
        public var deliveryAddress: DeliveryAddress { __data["deliveryAddress"] }
        /// Branch preparing the order
        public var branch: Branch { __data["branch"] }
        /// Business owning the branch
        public var business: Business { __data["business"] }

        /// CreateOrder.Item
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
            .field("lineTotal", Double.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateOrderMutation.Data.CreateOrder.Item.self
          ] }

          public var productId: String { __data["productId"] }
          public var name: String { __data["name"] }
          public var price: Double { __data["price"] }
          public var quantity: Int { __data["quantity"] }
          /// Presigned URL for the item image
          public var imageUrl: String? { __data["imageUrl"] }
          /// Line total (price * quantity)
          public var lineTotal: Double { __data["lineTotal"] }
        }

        /// CreateOrder.Discount
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
            CreateOrderMutation.Data.CreateOrder.Discount.self
          ] }

          public var id: String { __data["id"] }
          public var title: String { __data["title"] }
          public var amount: Double { __data["amount"] }
          public var type: GraphQLEnum<LlegoAPI.DiscountTypeEnum> { __data["type"] }
        }

        /// CreateOrder.DeliveryAddress
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
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateOrderMutation.Data.CreateOrder.DeliveryAddress.self
          ] }

          public var street: String { __data["street"] }
          public var city: String? { __data["city"] }
          public var reference: String? { __data["reference"] }
          public var addressType: GraphQLEnum<LlegoAPI.AddressTypeEnum> { __data["addressType"] }
          public var buildingName: String? { __data["buildingName"] }
          public var floor: String? { __data["floor"] }
          public var apartment: String? { __data["apartment"] }
          public var deliveryInstructions: String? { __data["deliveryInstructions"] }
        }

        /// CreateOrder.Branch
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
            CreateOrderMutation.Data.CreateOrder.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the branch avatar (inherits from business if not set)
          public var avatarUrl: String? { __data["avatarUrl"] }
        }

        /// CreateOrder.Business
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
            CreateOrderMutation.Data.CreateOrder.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }

}