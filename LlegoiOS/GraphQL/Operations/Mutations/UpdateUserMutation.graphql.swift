// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UpdateUserMutation: GraphQLMutation {
    public static let operationName: String = "UpdateUser"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateUser($input: UpdateUserInput!, $jwt: String!) { updateUser(input: $input, jwt: $jwt) { __typename id name username email phone avatar avatarUrl } }"#
      ))

    public var input: UpdateUserInput
    public var jwt: String

    public init(
      input: UpdateUserInput,
      jwt: String
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
        .field("updateUser", UpdateUser.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateUserMutation.Data.self
      ] }

      /// Actualizar perfil de usuario
      public var updateUser: UpdateUser { __data["updateUser"] }

      /// UpdateUser
      ///
      /// Parent Type: `UserType`
      public struct UpdateUser: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("username", String.self),
          .field("email", String.self),
          .field("phone", String?.self),
          .field("avatar", String?.self),
          .field("avatarUrl", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateUserMutation.Data.UpdateUser.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var username: String { __data["username"] }
        public var email: String { __data["email"] }
        public var phone: String? { __data["phone"] }
        public var avatar: String? { __data["avatar"] }
        /// URL firmada del avatar del usuario
        public var avatarUrl: String? { __data["avatarUrl"] }
      }
    }
  }

}