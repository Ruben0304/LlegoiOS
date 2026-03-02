// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SyncBusinessesWithBranchesQuery: GraphQLQuery {
    public static let operationName: String = "SyncBusinessesWithBranches"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SyncBusinessesWithBranches { syncBusinessesWithBranches { __typename id name globalRating avatar avatarUrl description tags isActive createdAt branches { __typename id businessId name address coordinates { __typename type coordinates } phone isActive status avatar avatarUrl coverImage coverUrl tipos deliveryRadius createdAt } } }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("syncBusinessesWithBranches", [SyncBusinessesWithBranch].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SyncBusinessesWithBranchesQuery.Data.self
      ] }

      /// Sincronizar negocios con sus branches (excluye datos sensibles como managerIds y ownerId)
      public var syncBusinessesWithBranches: [SyncBusinessesWithBranch] { __data["syncBusinessesWithBranches"] }

      /// SyncBusinessesWithBranch
      ///
      /// Parent Type: `BusinessSyncType`
      public struct SyncBusinessesWithBranch: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessSyncType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("globalRating", Double.self),
          .field("avatar", String?.self),
          .field("avatarUrl", String?.self),
          .field("description", String?.self),
          .field("tags", [String]?.self),
          .field("isActive", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("branches", [Branch].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SyncBusinessesWithBranchesQuery.Data.SyncBusinessesWithBranch.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var globalRating: Double { __data["globalRating"] }
        public var avatar: String? { __data["avatar"] }
        /// Presigned URL for the business avatar
        public var avatarUrl: String? { __data["avatarUrl"] }
        public var description: String? { __data["description"] }
        public var tags: [String]? { __data["tags"] }
        public var isActive: Bool { __data["isActive"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var branches: [Branch] { __data["branches"] }

        /// SyncBusinessesWithBranch.Branch
        ///
        /// Parent Type: `BranchSyncType`
        public struct Branch: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchSyncType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("businessId", String.self),
            .field("name", String.self),
            .field("address", String?.self),
            .field("coordinates", Coordinates.self),
            .field("phone", String.self),
            .field("isActive", Bool.self),
            .field("status", String?.self),
            .field("avatar", String?.self),
            .field("avatarUrl", String?.self),
            .field("coverImage", String?.self),
            .field("coverUrl", String?.self),
            .field("tipos", [String].self),
            .field("deliveryRadius", Double?.self),
            .field("createdAt", LlegoAPI.DateTime.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SyncBusinessesWithBranchesQuery.Data.SyncBusinessesWithBranch.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var businessId: String { __data["businessId"] }
          public var name: String { __data["name"] }
          public var address: String? { __data["address"] }
          public var coordinates: Coordinates { __data["coordinates"] }
          public var phone: String { __data["phone"] }
          public var isActive: Bool { __data["isActive"] }
          public var status: String? { __data["status"] }
          public var avatar: String? { __data["avatar"] }
          /// Presigned URL for the branch avatar
          public var avatarUrl: String? { __data["avatarUrl"] }
          public var coverImage: String? { __data["coverImage"] }
          /// Presigned URL for the branch cover image
          public var coverUrl: String? { __data["coverUrl"] }
          public var tipos: [String] { __data["tipos"] }
          public var deliveryRadius: Double? { __data["deliveryRadius"] }
          public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }

          /// SyncBusinessesWithBranch.Branch.Coordinates
          ///
          /// Parent Type: `CoordinatesSyncType`
          public struct Coordinates: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesSyncType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("type", String.self),
              .field("coordinates", [Double].self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              SyncBusinessesWithBranchesQuery.Data.SyncBusinessesWithBranch.Branch.Coordinates.self
            ] }

            public var type: String { __data["type"] }
            public var coordinates: [Double] { __data["coordinates"] }
          }
        }
      }
    }
  }

}