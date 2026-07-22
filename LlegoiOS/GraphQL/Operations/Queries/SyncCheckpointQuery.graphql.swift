// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SyncCheckpointQuery: GraphQLQuery {
    public static let operationName: String = "SyncCheckpoint"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SyncCheckpoint { syncCheckpoint { __typename businessIds branchIds productIds syncedAt } }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("syncCheckpoint", SyncCheckpoint.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SyncCheckpointQuery.Data.self
      ] }

      /// Checkpoint de sincronización: IDs actualmente activos (para que el cliente borre localmente lo que ya no está) y marca de tiempo del servidor a guardar como `since` para el próximo sync incremental.
      public var syncCheckpoint: SyncCheckpoint { __data["syncCheckpoint"] }

      /// SyncCheckpoint
      ///
      /// Parent Type: `SyncCheckpoint`
      public struct SyncCheckpoint: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.SyncCheckpoint }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("businessIds", [String].self),
          .field("branchIds", [String].self),
          .field("productIds", [String].self),
          .field("syncedAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SyncCheckpointQuery.Data.SyncCheckpoint.self
        ] }

        public var businessIds: [String] { __data["businessIds"] }
        public var branchIds: [String] { __data["branchIds"] }
        public var productIds: [String] { __data["productIds"] }
        public var syncedAt: LlegoAPI.DateTime { __data["syncedAt"] }
      }
    }
  }

}