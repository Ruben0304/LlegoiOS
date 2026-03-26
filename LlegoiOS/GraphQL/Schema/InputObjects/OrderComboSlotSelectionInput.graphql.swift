// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct OrderComboSlotSelectionInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      slotId: String,
      selectedOptions: [OrderComboSelectedOptionInput]
    ) {
      __data = InputDict([
        "slotId": slotId,
        "selectedOptions": selectedOptions
      ])
    }

    public var slotId: String {
      get { __data["slotId"] }
      set { __data["slotId"] = newValue }
    }

    public var selectedOptions: [OrderComboSelectedOptionInput] {
      get { __data["selectedOptions"] }
      set { __data["selectedOptions"] = newValue }
    }
  }

}