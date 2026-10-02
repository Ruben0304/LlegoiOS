// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RequestAccountDeletionMutation: GraphQLMutation {
    public static let operationName: String = "RequestAccountDeletion"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RequestAccountDeletion($jwt: String!) { requestAccountDeletion(jwt: $jwt) { __typename id scheduledDeletionAt } }"#
      ))

    public var jwt: String

    public init(jwt: String) {
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { ["jwt": jwt] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("requestAccountDeletion", RequestAccountDeletion.self, arguments: ["jwt": .variable("jwt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RequestAccountDeletionMutation.Data.self
      ] }

      /// Programar la eliminación de la cuenta con 30 días de gracia (Apple Guideline 5.1.1(v))
      public var requestAccountDeletion: RequestAccountDeletion { __data["requestAccountDeletion"] }

      /// RequestAccountDeletion
      ///
      /// Parent Type: `UserType`
      public struct RequestAccountDeletion: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("scheduledDeletionAt", LlegoAPI.DateTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RequestAccountDeletionMutation.Data.RequestAccountDeletion.self
        ] }

        public var id: String { __data["id"] }
        public var scheduledDeletionAt: LlegoAPI.DateTime? { __data["scheduledDeletionAt"] }
      }
    }
  }

}