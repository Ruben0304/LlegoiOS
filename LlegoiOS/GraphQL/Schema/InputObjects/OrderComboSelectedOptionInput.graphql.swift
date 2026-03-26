// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct OrderComboSelectedOptionInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      productId: String,
      quantity: Int32? = nil,
      modifiers: [OrderComboModifierInput]? = nil
    ) {
      __data = InputDict([
        "productId": productId,
        "quantity": quantity ?? GraphQLNullable.none,
        "modifiers": modifiers ?? GraphQLNullable.none
      ])
    }

    public var productId: String {
      get { __data["productId"] }
      set { __data["productId"] = newValue }
    }

    public var quantity: Int32? {
      get { __data["quantity"] }
      set { __data["quantity"] = newValue }
    }

    public var modifiers: [OrderComboModifierInput]? {
      get { __data["modifiers"] }
      set { __data["modifiers"] = newValue }
    }
  }

}