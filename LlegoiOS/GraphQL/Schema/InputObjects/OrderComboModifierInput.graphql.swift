// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct OrderComboModifierInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String
    ) {
      __data = InputDict([
        "name": name
      ])
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }
  }

}