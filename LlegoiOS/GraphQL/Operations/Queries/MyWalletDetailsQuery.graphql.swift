// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct MyWalletDetailsQuery: GraphQLQuery {
    public static let operationName: String = "MyWalletDetails"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyWalletDetails($jwt: String!, $limit: Int, $skip: Int, $currency: String) { me(jwt: $jwt) { __typename id wallet { __typename local usd } walletStatus } myWalletTransactions(jwt: $jwt, limit: $limit, skip: $skip, currency: $currency) { __typename id fromOwnerId fromOwnerType toOwnerId toOwnerType amount currency type status description createdAt completedAt } }"#
      ))

    public var jwt: String
    public var limit: GraphQLNullable<Int32>
    public var skip: GraphQLNullable<Int32>
    public var currency: GraphQLNullable<String>

    public init(
      jwt: String,
      limit: GraphQLNullable<Int32>,
      skip: GraphQLNullable<Int32>,
      currency: GraphQLNullable<String>
    ) {
      self.jwt = jwt
      self.limit = limit
      self.skip = skip
      self.currency = currency
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "jwt": jwt,
      "limit": limit,
      "skip": skip,
      "currency": currency
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me?.self, arguments: ["jwt": .variable("jwt")]),
        .field("myWalletTransactions", [MyWalletTransaction].self, arguments: [
          "jwt": .variable("jwt"),
          "limit": .variable("limit"),
          "skip": .variable("skip"),
          "currency": .variable("currency")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MyWalletDetailsQuery.Data.self
      ] }

      /// Usuario actual desde JWT
      public var me: Me? { __data["me"] }
      /// Obtener historial de transacciones del usuario actual
      public var myWalletTransactions: [MyWalletTransaction] { __data["myWalletTransactions"] }

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
          .field("wallet", Wallet.self),
          .field("walletStatus", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyWalletDetailsQuery.Data.Me.self
        ] }

        public var id: String { __data["id"] }
        public var wallet: Wallet { __data["wallet"] }
        public var walletStatus: String { __data["walletStatus"] }

        /// Me.Wallet
        ///
        /// Parent Type: `WalletBalanceType`
        public struct Wallet: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.WalletBalanceType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("local", Double.self),
            .field("usd", Double.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MyWalletDetailsQuery.Data.Me.Wallet.self
          ] }

          public var local: Double { __data["local"] }
          public var usd: Double { __data["usd"] }
        }
      }

      /// MyWalletTransaction
      ///
      /// Parent Type: `WalletTransactionType`
      public struct MyWalletTransaction: LlegoAPI.SelectionSet {
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
          MyWalletDetailsQuery.Data.MyWalletTransaction.self
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