// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RegisterInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String,
      email: String,
      password: String,
      phone: GraphQLNullable<String> = nil,
      role: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "role": role
      ])
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var email: String {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    public var password: String {
      get { __data["password"] }
      set { __data["password"] = newValue }
    }

    public var phone: GraphQLNullable<String> {
      get { __data["phone"] }
      set { __data["phone"] = newValue }
    }

    public var role: GraphQLNullable<String> {
      get { __data["role"] }
      set { __data["role"] = newValue }
    }
  }

}