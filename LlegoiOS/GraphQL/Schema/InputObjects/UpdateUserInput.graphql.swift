// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UpdateUserInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: GraphQLNullable<String> = nil,
      username: GraphQLNullable<String> = nil,
      phone: GraphQLNullable<String> = nil,
      avatar: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "username": username,
        "phone": phone,
        "avatar": avatar
      ])
    }

    public var name: GraphQLNullable<String> {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var username: GraphQLNullable<String> {
      get { __data["username"] }
      set { __data["username"] = newValue }
    }

    public var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
    }

    public var avatar: GraphQLNullable<String> {
      get { __data["avatar"] }
      set { __data["avatar"] = newValue }
    }
  }

}