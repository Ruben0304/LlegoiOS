// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct LikeBranchMutation: GraphQLMutation {
    public static let operationName: String = "LikeBranch"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation LikeBranch($branchId: String!, $jwt: String) { likeBranch(branchId: $branchId, jwt: $jwt) { __typename id userId branchId createdAt } }"#
      ))

    public var branchId: String
    public var jwt: GraphQLNullable<String>

    public init(
      branchId: String,
      jwt: GraphQLNullable<String>
    ) {
      self.branchId = branchId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "branchId": branchId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("likeBranch", LikeBranch.self, arguments: [
          "branchId": .variable("branchId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LikeBranchMutation.Data.self
      ] }

      /// Agregar like a un branch
      public var likeBranch: LikeBranch { __data["likeBranch"] }

      /// LikeBranch
      ///
      /// Parent Type: `BranchLikeType`
      public struct LikeBranch: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchLikeType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("userId", String.self),
          .field("branchId", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LikeBranchMutation.Data.LikeBranch.self
        ] }

        public var id: String { __data["id"] }
        public var userId: String { __data["userId"] }
        public var branchId: String { __data["branchId"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}