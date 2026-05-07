// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct CreateOrderMutation: GraphQLMutation {
    public static let operationName: String = "CreateOrder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CreateOrder($input: CreateOrderInput!, $jwt: String!) { createOrder(input: $input, jwt: $jwt) { __typename id orderNumber status subtotal deliveryFee total currency paymentMethod paymentStatus createdAt deliveryMode items { __typename itemType itemId productId name basePrice finalPrice price quantity imageUrl lineTotal discountType discountValue comboSelections { __typename slotId slotName selectedOptions { __typename productId name price quantity priceAdjustment modifiers { __typename name priceAdjustment } } } } discounts { __typename id title amount type } deliveryAddress { __typename street city reference addressType buildingName floor apartment deliveryInstructions } pickupAddress { __typename street } scheduledFor branch { __typename id name avatarUrl } business { __typename id name } } }"#
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
          .field("deliveryMode", String.self),
          .field("items", [Item].self),
          .field("discounts", [Discount].self),
          .field("deliveryAddress", DeliveryAddress.self),
          .field("pickupAddress", PickupAddress?.self),
          .field("scheduledFor", LlegoAPI.DateTime?.self),
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
        public var deliveryMode: String { __data["deliveryMode"] }
        /// Order items
        public var items: [Item] { __data["items"] }
        /// Applied discounts
        public var discounts: [Discount] { __data["discounts"] }
        /// Delivery address
        public var deliveryAddress: DeliveryAddress { __data["deliveryAddress"] }
        /// Pickup address (branch location)
        public var pickupAddress: PickupAddress? { __data["pickupAddress"] }
        public var scheduledFor: LlegoAPI.DateTime? { __data["scheduledFor"] }
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
            .field("itemType", String.self),
            .field("itemId", String.self),
            .field("productId", String.self),
            .field("name", String.self),
            .field("basePrice", Double.self),
            .field("finalPrice", Double.self),
            .field("price", Double.self),
            .field("quantity", Int.self),
            .field("imageUrl", String?.self),
            .field("lineTotal", Double.self),
            .field("discountType", String?.self),
            .field("discountValue", Double?.self),
            .field("comboSelections", [ComboSelection]?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateOrderMutation.Data.CreateOrder.Item.self
          ] }

          public var itemType: String { __data["itemType"] }
          public var itemId: String { __data["itemId"] }
          public var productId: String { __data["productId"] }
          public var name: String { __data["name"] }
          public var basePrice: Double { __data["basePrice"] }
          public var finalPrice: Double { __data["finalPrice"] }
          public var price: Double { __data["price"] }
          public var quantity: Int { __data["quantity"] }
          /// Presigned URL for the item image
          public var imageUrl: String? { __data["imageUrl"] }
          /// Line total (price * quantity)
          public var lineTotal: Double { __data["lineTotal"] }
          public var discountType: String? { __data["discountType"] }
          public var discountValue: Double? { __data["discountValue"] }
          public var comboSelections: [ComboSelection]? { __data["comboSelections"] }

          /// CreateOrder.Item.ComboSelection
          ///
          /// Parent Type: `OrderComboSelectionType`
          public struct ComboSelection: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderComboSelectionType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("slotId", String.self),
              .field("slotName", String.self),
              .field("selectedOptions", [SelectedOption].self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              CreateOrderMutation.Data.CreateOrder.Item.ComboSelection.self
            ] }

            public var slotId: String { __data["slotId"] }
            public var slotName: String { __data["slotName"] }
            public var selectedOptions: [SelectedOption] { __data["selectedOptions"] }

            /// CreateOrder.Item.ComboSelection.SelectedOption
            ///
            /// Parent Type: `OrderComboSelectedOptionType`
            public struct SelectedOption: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderComboSelectedOptionType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("productId", String.self),
                .field("name", String.self),
                .field("price", Double.self),
                .field("quantity", Int.self),
                .field("priceAdjustment", Double.self),
                .field("modifiers", [Modifier].self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                CreateOrderMutation.Data.CreateOrder.Item.ComboSelection.SelectedOption.self
              ] }

              public var productId: String { __data["productId"] }
              public var name: String { __data["name"] }
              public var price: Double { __data["price"] }
              public var quantity: Int { __data["quantity"] }
              public var priceAdjustment: Double { __data["priceAdjustment"] }
              public var modifiers: [Modifier] { __data["modifiers"] }

              /// CreateOrder.Item.ComboSelection.SelectedOption.Modifier
              ///
              /// Parent Type: `OrderComboModifierType`
              public struct Modifier: LlegoAPI.SelectionSet {
                @_spi(Unsafe) public let __data: DataDict
                @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

                @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderComboModifierType }
                @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                  .field("__typename", String.self),
                  .field("name", String.self),
                  .field("priceAdjustment", Double.self),
                ] }
                @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                  CreateOrderMutation.Data.CreateOrder.Item.ComboSelection.SelectedOption.Modifier.self
                ] }

                public var name: String { __data["name"] }
                public var priceAdjustment: Double { __data["priceAdjustment"] }
              }
            }
          }
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

        /// CreateOrder.PickupAddress
        ///
        /// Parent Type: `PickupAddressType`
        public struct PickupAddress: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PickupAddressType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("street", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            CreateOrderMutation.Data.CreateOrder.PickupAddress.self
          ] }

          public var street: String? { __data["street"] }
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