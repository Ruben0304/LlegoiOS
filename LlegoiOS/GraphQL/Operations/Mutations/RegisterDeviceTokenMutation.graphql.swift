// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RegisterDeviceTokenMutation: GraphQLMutation {
    public static let operationName: String = "RegisterDeviceToken"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegisterDeviceToken($input: RegisterDeviceTokenInput!, $jwt: String) { registerDeviceToken(input: $input, jwt: $jwt) { __typename id userId token platform appVersion osVersion isActive createdAt updatedAt } }"#
      ))

    public var input: RegisterDeviceTokenInput
    public var jwt: GraphQLNullable<String>

    public init(
      input: RegisterDeviceTokenInput,
      jwt: GraphQLNullable<String>
    ) {
      self.input = input
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "input": input,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("registerDeviceToken", RegisterDeviceToken.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterDeviceTokenMutation.Data.self
      ] }

      /// Register device token for push notifications
      public var registerDeviceToken: RegisterDeviceToken { __data["registerDeviceToken"] }

      /// RegisterDeviceToken
      ///
      /// Parent Type: `DeviceTokenType`
      public struct RegisterDeviceToken: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.DeviceTokenType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("userId", String?.self),
          .field("token", String.self),
          .field("platform", GraphQLEnum<LlegoAPI.DevicePlatformEnum>.self),
          .field("appVersion", String?.self),
          .field("osVersion", String?.self),
          .field("isActive", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("updatedAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterDeviceTokenMutation.Data.RegisterDeviceToken.self
        ] }

        public var id: String { __data["id"] }
        public var userId: String? { __data["userId"] }
        public var token: String { __data["token"] }
        public var platform: GraphQLEnum<LlegoAPI.DevicePlatformEnum> { __data["platform"] }
        public var appVersion: String? { __data["appVersion"] }
        public var osVersion: String? { __data["osVersion"] }
        public var isActive: Bool { __data["isActive"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var updatedAt: LlegoAPI.DateTime { __data["updatedAt"] }
      }
    }
  }

}