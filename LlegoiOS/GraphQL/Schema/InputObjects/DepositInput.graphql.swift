// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct DepositInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      amount: Double,
      currency: String,
      source: String,
      description: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "amount": amount,
        "currency": currency,
        "source": source,
        "description": description
      ])
    }

    public var amount: Double {
      get { __data["amount"] }
      set { __data["amount"] = newValue }
    }

    public var currency: String {
      get { __data["currency"] }
      set { __data["currency"] = newValue }
    }

    public var source: String {
      get { __data["source"] }
      set { __data["source"] = newValue }
    }

    public var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }
  }

}