// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AddOrderCommentMutation: GraphQLMutation {
    public static let operationName: String = "AddOrderComment"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AddOrderComment($input: AddOrderCommentInput!, $jwt: String!) { addOrderComment(input: $input, jwt: $jwt) { __typename id comments { __typename id author message timestamp } } }"#
      ))

    public var input: AddOrderCommentInput
    public var jwt: String

    public init(
      input: AddOrderCommentInput,
      jwt: String
    ) {
      self.input = input
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "input": input,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("addOrderComment", AddOrderComment.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AddOrderCommentMutation.Data.self
      ] }

      /// Añadir comentario al pedido
      public var addOrderComment: AddOrderComment { __data["addOrderComment"] }

      /// AddOrderComment
      ///
      /// Parent Type: `OrderType`
      public struct AddOrderComment: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("comments", [Comment].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AddOrderCommentMutation.Data.AddOrderComment.self
        ] }

        public var id: String { __data["id"] }
        public var comments: [Comment] { __data["comments"] }

        /// AddOrderComment.Comment
        ///
        /// Parent Type: `OrderCommentType`
        public struct Comment: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.OrderCommentType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("author", GraphQLEnum<LlegoAPI.OrderActorEnum>.self),
            .field("message", String.self),
            .field("timestamp", LlegoAPI.DateTime.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AddOrderCommentMutation.Data.AddOrderComment.Comment.self
          ] }

          public var id: String { __data["id"] }
          public var author: GraphQLEnum<LlegoAPI.OrderActorEnum> { __data["author"] }
          public var message: String { __data["message"] }
          public var timestamp: LlegoAPI.DateTime { __data["timestamp"] }
        }
      }
    }
  }

}