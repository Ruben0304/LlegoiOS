// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SearchMenusQuery: GraphQLQuery {
    public static let operationName: String = "SearchMenus"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchMenus($query: String!, $first: Int! = 20, $jwt: String) { searchMenus(query: $query, first: $first, jwt: $jwt) { __typename menu { __typename id branchId imageUrl ocrStatus isActive } matchCount matches { __typename lineIndex start end text polygon } branch { __typename id name } } }"#
      ))

    public var query: String
    public var first: Int32
    public var jwt: GraphQLNullable<String>

    public init(
      query: String,
      first: Int32 = 20,
      jwt: GraphQLNullable<String>
    ) {
      self.query = query
      self.first = first
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "query": query,
      "first": first,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("searchMenus", [SearchMenu].self, arguments: [
          "query": .variable("query"),
          "first": .variable("first"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchMenusQuery.Data.self
      ] }

      /// Busca texto dentro de las cartas de sucursales de negocios aprobados (máx. 20)
      public var searchMenus: [SearchMenu] { __data["searchMenus"] }

      /// SearchMenu
      ///
      /// Parent Type: `MenuSearchResultType`
      public struct SearchMenu: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.MenuSearchResultType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("menu", Menu.self),
          .field("matchCount", Int.self),
          .field("matches", [Match].self),
          .field("branch", Branch?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchMenusQuery.Data.SearchMenu.self
        ] }

        public var menu: Menu { __data["menu"] }
        public var matchCount: Int { __data["matchCount"] }
        public var matches: [Match] { __data["matches"] }
        public var branch: Branch? { __data["branch"] }

        /// SearchMenu.Menu
        ///
        /// Parent Type: `BranchMenuType`
        public struct Menu: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchMenuType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("branchId", String.self),
            .field("imageUrl", String.self),
            .field("ocrStatus", String.self),
            .field("isActive", Bool.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchMenusQuery.Data.SearchMenu.Menu.self
          ] }

          public var id: String { __data["id"] }
          public var branchId: String { __data["branchId"] }
          public var imageUrl: String { __data["imageUrl"] }
          public var ocrStatus: String { __data["ocrStatus"] }
          public var isActive: Bool { __data["isActive"] }
        }

        /// SearchMenu.Match
        ///
        /// Parent Type: `MenuMatchType`
        public struct Match: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.MenuMatchType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("lineIndex", Int.self),
            .field("start", Int.self),
            .field("end", Int.self),
            .field("text", String.self),
            .field("polygon", [[Double]].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchMenusQuery.Data.SearchMenu.Match.self
          ] }

          public var lineIndex: Int { __data["lineIndex"] }
          public var start: Int { __data["start"] }
          public var end: Int { __data["end"] }
          public var text: String { __data["text"] }
          /// 4 puntos normalizados (0-1) [[x, y], ...] sobre la imagen
          public var polygon: [[Double]] { __data["polygon"] }
        }

        /// SearchMenu.Branch
        ///
        /// Parent Type: `BranchType`
        public struct Branch: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchMenusQuery.Data.SearchMenu.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
        }
      }
    }
  }

}