// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBusinessDetailQuery: GraphQLQuery {
    public static let operationName: String = "GetBusinessDetail"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBusinessDetail($id: String!) { business(id: $id) { __typename id name avatarUrl } }"#
      ))

    public var id: String

    public init(id: String) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("business", Business?.self, arguments: ["id": .variable("id")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBusinessDetailQuery.Data.self
      ] }

      /// Obtener negocio por ID
      public var business: Business? { __data["business"] }

      /// Business
      ///
      /// Parent Type: `BusinessType`
      public struct Business: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("avatarUrl", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBusinessDetailQuery.Data.Business.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        /// Presigned URL for the business avatar
        public var avatarUrl: String? { __data["avatarUrl"] }
      }
    }
  }

}