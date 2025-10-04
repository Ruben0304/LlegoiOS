// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchBranchesQuery: GraphQLQuery {
    public static let operationName: String = "SearchBranches"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchBranches($query: String!) { searchBranches(query: $query) { __typename id businessId name address coordinates { __typename type coordinates } phone status createdAt } }"#
      ))

    public var query: String

    public init(query: String) {
      self.query = query
    }

    @_spi(Unsafe) public var __variables: Variables? { ["query": query] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchBranches", [SearchBranch].self, arguments: ["query": .variable("query")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchBranchesQuery.Data.self
      ] }

      /// Buscar sucursales
      public var searchBranches: [SearchBranch] { __data["searchBranches"] }

      /// SearchBranch
      ///
      /// Parent Type: `BranchType`
      public struct SearchBranch: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("businessId", String.self),
          .field("name", String.self),
          .field("address", String.self),
          .field("coordinates", Coordinates.self),
          .field("phone", String.self),
          .field("status", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchBranchesQuery.Data.SearchBranch.self
        ] }

        public var id: String { __data["id"] }
        public var businessId: String { __data["businessId"] }
        public var name: String { __data["name"] }
        public var address: String { __data["address"] }
        public var coordinates: Coordinates { __data["coordinates"] }
        public var phone: String { __data["phone"] }
        public var status: String { __data["status"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }

        /// SearchBranch.Coordinates
        ///
        /// Parent Type: `CoordinatesType`
        public struct Coordinates: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CoordinatesType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("coordinates", [Double].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchBranchesQuery.Data.SearchBranch.Coordinates.self
          ] }

          public var type: String { __data["type"] }
          public var coordinates: [Double] { __data["coordinates"] }
        }
      }
    }
  }

}