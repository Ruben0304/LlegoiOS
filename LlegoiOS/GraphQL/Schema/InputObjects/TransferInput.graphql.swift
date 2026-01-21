// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct TransferInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      toOwnerId: GraphQLNullable<String> = nil,
      toOwnerEmail: GraphQLNullable<String> = nil,
      toOwnerUsername: GraphQLNullable<String> = nil,
      toOwnerType: String,
      amount: Double,
      currency: String,
      description: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "toOwnerId": toOwnerId,
        "toOwnerEmail": toOwnerEmail,
        "toOwnerUsername": toOwnerUsername,
        "toOwnerType": toOwnerType,
        "amount": amount,
        "currency": currency,
        "description": description
      ])
    }

    public var toOwnerId: GraphQLNullable<String> {
      get { __data["toOwnerId"] }
      set { __data["toOwnerId"] = newValue }
    }

    public var toOwnerEmail: GraphQLNullable<String> {
      get { __data["toOwnerEmail"] }
      set { __data["toOwnerEmail"] = newValue }
    }

    public var toOwnerUsername: GraphQLNullable<String> {
      get { __data["toOwnerUsername"] }
      set { __data["toOwnerUsername"] = newValue }
    }

    public var toOwnerType: String {
      get { __data["toOwnerType"] }
      set { __data["toOwnerType"] = newValue }
    }

    public var amount: Double {
      get { __data["amount"] }
      set { __data["amount"] = newValue }
    }

    public var currency: String {
      get { __data["currency"] }
      set { __data["currency"] = newValue }
    }

    public var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }
  }

}