// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct CancelAccountDeletionMutation: GraphQLMutation {
    public static let operationName: String = "CancelAccountDeletion"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation CancelAccountDeletion($jwt: String!) { cancelAccountDeletion(jwt: $jwt) { __typename id scheduledDeletionAt } }"#
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
        .field("cancelAccountDeletion", CancelAccountDeletion.self, arguments: ["jwt": .variable("jwt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        CancelAccountDeletionMutation.Data.self
      ] }

      /// Cancelar una solicitud de eliminación de cuenta pendiente
      public var cancelAccountDeletion: CancelAccountDeletion { __data["cancelAccountDeletion"] }

      /// CancelAccountDeletion
      ///
      /// Parent Type: `UserType`
      public struct CancelAccountDeletion: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("scheduledDeletionAt", LlegoAPI.DateTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          CancelAccountDeletionMutation.Data.CancelAccountDeletion.self
        ] }

        public var id: String { __data["id"] }
        public var scheduledDeletionAt: LlegoAPI.DateTime? { __data["scheduledDeletionAt"] }
      }
    }
  }

}