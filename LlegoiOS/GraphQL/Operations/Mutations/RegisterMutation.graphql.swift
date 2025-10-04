// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RegisterMutation: GraphQLMutation {
    public static let operationName: String = "Register"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation Register($input: RegisterInput!) { register(input: $input) { __typename accessToken tokenType user { __typename id name email phone role createdAt } } }"#
      ))

    public var input: RegisterInput

    public init(input: RegisterInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("register", Register.self, arguments: ["input": .variable("input")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterMutation.Data.self
      ] }

      /// Register a new user
      public var register: Register { __data["register"] }

      /// Register
      ///
      /// Parent Type: `AuthResponse`
      public struct Register: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AuthResponse }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String.self),
          .field("tokenType", String.self),
          .field("user", User.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterMutation.Data.Register.self
        ] }

        public var accessToken: String { __data["accessToken"] }
        public var tokenType: String { __data["tokenType"] }
        public var user: User { __data["user"] }

        /// Register.User
        ///
        /// Parent Type: `UserData`
        public struct User: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserData }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("email", String.self),
            .field("phone", String?.self),
            .field("role", String.self),
            .field("createdAt", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RegisterMutation.Data.Register.User.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var email: String { __data["email"] }
          public var phone: String? { __data["phone"] }
          public var role: String { __data["role"] }
          public var createdAt: String { __data["createdAt"] }
        }
      }
    }
  }

}