// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UnlikeBranchMutation: GraphQLMutation {
    public static let operationName: String = "UnlikeBranch"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UnlikeBranch($branchId: String!, $jwt: String) { unlikeBranch(branchId: $branchId, jwt: $jwt) }"#
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
        .field("unlikeBranch", Bool.self, arguments: [
          "branchId": .variable("branchId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnlikeBranchMutation.Data.self
      ] }

      /// Remover like de un branch
      public var unlikeBranch: Bool { __data["unlikeBranch"] }
    }
  }

}