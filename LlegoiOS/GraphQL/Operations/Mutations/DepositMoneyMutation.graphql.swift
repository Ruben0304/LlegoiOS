// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct DepositMoneyMutation: GraphQLMutation {
    public static let operationName: String = "DepositMoney"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DepositMoney($jwt: String!, $input: DepositInput!) { depositMoney(jwt: $jwt, input: $input) { __typename id fromOwnerId fromOwnerType toOwnerId toOwnerType amount currency type status description createdAt completedAt } }"#
      ))

    public var jwt: String
    public var input: DepositInput

    public init(
      jwt: String,
      input: DepositInput
    ) {
      self.jwt = jwt
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "jwt": jwt,
      "input": input
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("depositMoney", DepositMoney.self, arguments: [
          "jwt": .variable("jwt"),
          "input": .variable("input")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DepositMoneyMutation.Data.self
      ] }

      /// Depositar dinero en la wallet
      public var depositMoney: DepositMoney { __data["depositMoney"] }

      /// DepositMoney
      ///
      /// Parent Type: `WalletTransactionType`
      public struct DepositMoney: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.WalletTransactionType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("fromOwnerId", String?.self),
          .field("fromOwnerType", String?.self),
          .field("toOwnerId", String?.self),
          .field("toOwnerType", String?.self),
          .field("amount", Double.self),
          .field("currency", String.self),
          .field("type", String.self),
          .field("status", String.self),
          .field("description", String?.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("completedAt", LlegoAPI.DateTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DepositMoneyMutation.Data.DepositMoney.self
        ] }

        public var id: String { __data["id"] }
        public var fromOwnerId: String? { __data["fromOwnerId"] }
        public var fromOwnerType: String? { __data["fromOwnerType"] }
        public var toOwnerId: String? { __data["toOwnerId"] }
        public var toOwnerType: String? { __data["toOwnerType"] }
        public var amount: Double { __data["amount"] }
        public var currency: String { __data["currency"] }
        public var type: String { __data["type"] }
        public var status: String { __data["status"] }
        public var description: String? { __data["description"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var completedAt: LlegoAPI.DateTime? { __data["completedAt"] }
      }
    }
  }

}