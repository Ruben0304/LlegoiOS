// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RegisterDeviceTokenInput: InputObject {
    @_spi(Unsafe) public private(set) var __data: InputDict

    @_spi(Unsafe) public init(_ data: InputDict) {
      __data = data
    }

    public init(
      token: String,
      platform: GraphQLEnum<DevicePlatformEnum>,
      appVersion: GraphQLNullable<String> = nil,
      osVersion: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "token": token,
        "platform": platform,
        "appVersion": appVersion,
        "osVersion": osVersion
      ])
    }

    public var token: String {
      get { __data["token"] }
      set { __data["token"] = newValue }
    }

    public var platform: GraphQLEnum<DevicePlatformEnum> {
      get { __data["platform"] }
      set { __data["platform"] = newValue }
    }

    public var appVersion: GraphQLNullable<String> {
      get { __data["appVersion"] }
      set { __data["appVersion"] = newValue }
    }

    public var osVersion: GraphQLNullable<String> {
      get { __data["osVersion"] }
      set { __data["osVersion"] = newValue }
    }
  }

}