// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct CreateOrderInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      branchId: String,
      items: [OrderItemInput],
      deliveryAddress: DeliveryAddressInput,
      paymentMethod: String,
      paymentIntentId: GraphQLNullable<String> = nil,
      comments: GraphQLNullable<String> = nil,
      promoCode: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "branchId": branchId,
        "items": items,
        "deliveryAddress": deliveryAddress,
        "paymentMethod": paymentMethod,
        "paymentIntentId": paymentIntentId,
        "comments": comments,
        "promoCode": promoCode
      ])
    }

    public var branchId: String {
      get { __data["branchId"] }
      set { __data["branchId"] = newValue }
    }

    public var items: [OrderItemInput] {
      get { __data["items"] }
      set { __data["items"] = newValue }
    }

    public var deliveryAddress: DeliveryAddressInput {
      get { __data["deliveryAddress"] }
      set { __data["deliveryAddress"] = newValue }
    }

    public var paymentMethod: String {
      get { __data["paymentMethod"] }
      set { __data["paymentMethod"] = newValue }
    }

    public var paymentIntentId: GraphQLNullable<String> {
      get { __data["paymentIntentId"] }
      set { __data["paymentIntentId"] = newValue }
    }

    public var comments: GraphQLNullable<String> {
      get { __data["comments"] }
      set { __data["comments"] = newValue }
    }

    public var promoCode: GraphQLNullable<String> {
      get { __data["promoCode"] }
      set { __data["promoCode"] = newValue }
    }
  }

}