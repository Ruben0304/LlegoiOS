// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct MeQuery: GraphQLQuery {
    public static let operationName: String = "Me"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me($jwt: String!) { me(jwt: $jwt) { __typename id name email phone role createdAt providerUserId } }"#
      ))

    public var jwt: String

    public init(jwt: String) {
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { ["jwt": jwt] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me?.self, arguments: ["jwt": .variable("jwt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      /// Usuario actual desde JWT
      public var me: Me? { __data["me"] }

      /// Me
      ///
      /// Parent Type: `UserType`
      public struct Me: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("email", String.self),
          .field("phone", String?.self),
          .field("role", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("providerUserId", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var email: String { __data["email"] }
        public var phone: String? { __data["phone"] }
        public var role: String { __data["role"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var providerUserId: String? { __data["providerUserId"] }
      }
    }
  }

}