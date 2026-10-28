// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBranchMenuQuery: GraphQLQuery {
    public static let operationName: String = "GetBranchMenu"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBranchMenu($branchId: String!, $jwt: String) { branchMenu(branchId: $branchId, jwt: $jwt) { __typename id branchId imageUrl ocrStatus isActive } }"#
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

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("branchMenu", BranchMenu?.self, arguments: [
          "branchId": .variable("branchId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBranchMenuQuery.Data.self
      ] }

      /// Carta (menú OCR) activa de una sucursal
      public var branchMenu: BranchMenu? { __data["branchMenu"] }

      /// BranchMenu
      ///
      /// Parent Type: `BranchMenuType`
      public struct BranchMenu: LlegoAPI.SelectionSet {
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
          GetBranchMenuQuery.Data.BranchMenu.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var imageUrl: String { __data["imageUrl"] }
        public var ocrStatus: String { __data["ocrStatus"] }
        public var isActive: Bool { __data["isActive"] }
      }
    }
  }

}