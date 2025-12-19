// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AppleLoginInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      identityToken: String,
      authorizationCode: GraphQLNullable<String> = nil,
      nonce: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "identityToken": identityToken,
        "authorizationCode": authorizationCode,
        "nonce": nonce
      ])
    }

    public var identityToken: String {
      get { __data["identityToken"] }
      set { __data["identityToken"] = newValue }
    }

    public var authorizationCode: GraphQLNullable<String> {
      get { __data["authorizationCode"] }
      set { __data["authorizationCode"] = newValue }
    }

    public var nonce: GraphQLNullable<String> {
      get { __data["nonce"] }
      set { __data["nonce"] = newValue }
    }
  }

}