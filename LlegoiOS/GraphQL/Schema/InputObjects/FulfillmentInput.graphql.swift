// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct FulfillmentInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      type: GraphQLEnum<FulfillmentTypeEnum>,
      pickupBranchId: GraphQLNullable<String> = nil,
      pickupWindowId: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "type": type,
        "pickupBranchId": pickupBranchId,
        "pickupWindowId": pickupWindowId
      ])
    }

    public var type: GraphQLEnum<FulfillmentTypeEnum> {
      get { __data["type"] }
      set { __data["type"] = newValue }
    }

    public var pickupBranchId: GraphQLNullable<String> {
      get { __data["pickupBranchId"] }
      set { __data["pickupBranchId"] = newValue }
    }

    public var pickupWindowId: GraphQLNullable<String> {
      get { __data["pickupWindowId"] }
      set { __data["pickupWindowId"] = newValue }
    }
  }

}