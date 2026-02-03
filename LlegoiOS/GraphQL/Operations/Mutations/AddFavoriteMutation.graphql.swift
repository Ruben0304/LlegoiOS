// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AddFavoriteMutation: GraphQLMutation {
    public static let operationName: String = "AddFavorite"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AddFavorite($productId: String!, $jwt: String) { addFavorite(productId: $productId, jwt: $jwt) { __typename id userId productId type createdAt } }"#
      ))

    public var productId: String
    public var jwt: GraphQLNullable<String>

    public init(
      productId: String,
      jwt: GraphQLNullable<String>
    ) {
      self.productId = productId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "productId": productId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("addFavorite", AddFavorite?.self, arguments: [
          "productId": .variable("productId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AddFavoriteMutation.Data.self
      ] }

      /// Agregar producto a favoritos
      public var addFavorite: AddFavorite? { __data["addFavorite"] }

      /// AddFavorite
      ///
      /// Parent Type: `FavoriteCartType`
      public struct AddFavorite: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FavoriteCartType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("userId", String.self),
          .field("productId", String.self),
          .field("type", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AddFavoriteMutation.Data.AddFavorite.self
        ] }

        public var id: String { __data["id"] }
        public var userId: String { __data["userId"] }
        public var productId: String { __data["productId"] }
        public var type: String { __data["type"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}