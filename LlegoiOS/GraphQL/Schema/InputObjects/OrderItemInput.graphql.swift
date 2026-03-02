// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct OrderItemInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      quantity: Int32,
      itemType: GraphQLEnum<OrderItemTypeInput>? = nil,
      productId: GraphQLNullable<String> = nil,
      showcaseId: GraphQLNullable<String> = nil,
      description: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "quantity": quantity,
        "itemType": itemType ?? GraphQLNullable.none,
        "productId": productId,
        "showcaseId": showcaseId,
        "description": description
      ])
    }

    public var quantity: Int32 {
      get { __data["quantity"] }
      set { __data["quantity"] = newValue }
    }

    public var itemType: GraphQLEnum<OrderItemTypeInput>? {
      get { __data["itemType"] }
      set { __data["itemType"] = newValue }
    }

    public var productId: GraphQLNullable<String> {
      get { __data["productId"] }
      set { __data["productId"] = newValue }
    }

    public var showcaseId: GraphQLNullable<String> {
      get { __data["showcaseId"] }
      set { __data["showcaseId"] = newValue }
    }

    public var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }
  }

}