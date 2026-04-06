// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct ResubmitOrderInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      orderId: String,
      items: GraphQLNullable<[OrderItemInput]> = nil,
      comment: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "orderId": orderId,
        "items": items,
        "comment": comment
      ])
    }

    public var orderId: String {
      get { __data["orderId"] }
      set { __data["orderId"] = newValue }
    }

    public var items: GraphQLNullable<[OrderItemInput]> {
      get { __data["items"] }
      set { __data["items"] = newValue }
    }

    public var comment: GraphQLNullable<String> {
      get { __data["comment"] }
      set { __data["comment"] = newValue }
    }
  }

}