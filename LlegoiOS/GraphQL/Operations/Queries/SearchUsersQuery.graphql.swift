// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchUsersQuery: GraphQLQuery {
    public static let operationName: String = "SearchUsers"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchUsers($query: String!, $jwt: String!) { searchUsers(query: $query, jwt: $jwt) { __typename id name username email avatar avatarUrl } }"#
      ))

    public var query: String
    public var jwt: String

    public init(
      query: String,
      jwt: String
    ) {
      self.query = query
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchUsers", [SearchUser].self, arguments: [
          "query": .variable("query"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchUsersQuery.Data.self
      ] }

      /// Buscar usuarios (requiere autenticación)
      public var searchUsers: [SearchUser] { __data["searchUsers"] }

      /// SearchUser
      ///
      /// Parent Type: `UserType`
      public struct SearchUser: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("username", String.self),
          .field("email", String.self),
          .field("avatar", String?.self),
          .field("avatarUrl", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchUsersQuery.Data.SearchUser.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var username: String { __data["username"] }
        public var email: String { __data["email"] }
        public var avatar: String? { __data["avatar"] }
        /// URL firmada del avatar del usuario
        public var avatarUrl: String? { __data["avatarUrl"] }
      }
    }
  }

}