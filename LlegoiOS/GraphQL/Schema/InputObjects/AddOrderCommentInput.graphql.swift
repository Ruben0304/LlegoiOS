// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AddOrderCommentInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      orderId: String,
      message: String
    ) {
      __data = InputDict([
        "orderId": orderId,
        "message": message
      ])
    }

    public var orderId: String {
      get { __data["orderId"] }
      set { __data["orderId"] = newValue }
    }

    public var message: String {
      get { __data["message"] }
      set { __data["message"] = newValue }
    }
  }

}