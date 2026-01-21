// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct MyWalletBalanceQuery: GraphQLQuery {
    public static let operationName: String = "MyWalletBalance"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query MyWalletBalance($jwt: String!) { me(jwt: $jwt) { __typename id wallet { __typename local usd } walletStatus } }"#
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
        MyWalletBalanceQuery.Data.self
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
          .field("wallet", Wallet.self),
          .field("walletStatus", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MyWalletBalanceQuery.Data.Me.self
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
            MyWalletBalanceQuery.Data.Me.Wallet.self
          ] }

          public var local: Double { __data["local"] }
          public var usd: Double { __data["usd"] }
        }
      }
    }
  }

}