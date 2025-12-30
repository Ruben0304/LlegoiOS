// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AIChatQuery: GraphQLQuery {
    public static let operationName: String = "AIChat"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AIChat($message: String!, $sessionId: String!) { aiChat(input: { message: $message, sessionId: $sessionId }) { __typename output { __typename type AItext ids entities { __typename ... on PaymentMethodType { id currency method } ... on ProductType { id name description price currency image availability } ... on BranchType { id name address phone status coordinates { __typename type coordinates } } } } } }"#
      ))

    public var message: String
    public var sessionId: String

    public init(
      message: String,
      sessionId: String
    ) {
      self.message = message
      self.sessionId = sessionId
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "message": message,
      "sessionId": sessionId
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("aiChat", AiChat?.self, arguments: ["input": [
          "message": .variable("message"),
          "sessionId": .variable("sessionId")
        ]]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AIChatQuery.Data.self
      ] }

      /// Send a message to the AI assistant and get a response
      public var aiChat: AiChat? { __data["aiChat"] }

      /// AiChat
      ///
      /// Parent Type: `AiAssistantResponseType`
      public struct AiChat: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiAssistantResponseType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("output", Output.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AIChatQuery.Data.AiChat.self
        ] }

        /// Response output from AI assistant
        public var output: Output { __data["output"] }

        /// AiChat.Output
        ///
        /// Parent Type: `AiAssistantOutputType`
        public struct Output: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiAssistantOutputType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("type", String.self),
            .field("AItext", String.self),
            .field("ids", [String].self),
            .field("entities", [Entity]?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AIChatQuery.Data.AiChat.Output.self
          ] }

          /// Type of response (e.g., 'payment_method', 'products', 'branches')
          public var type: String { __data["type"] }
          /// AI-generated response text
          public var aItext: String { __data["AItext"] }
          /// List of relevant IDs (for debugging)
          public var ids: [String] { __data["ids"] }
          /// List of resolved entities (products, branches, or payment methods)
          public var entities: [Entity]? { __data["entities"] }

          /// AiChat.Output.Entity
          ///
          /// Parent Type: `EntityType`
          public struct Entity: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Unions.EntityType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .inlineFragment(AsPaymentMethodType.self),
              .inlineFragment(AsProductType.self),
              .inlineFragment(AsBranchType.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AIChatQuery.Data.AiChat.Output.Entity.self
            ] }

            public var asPaymentMethodType: AsPaymentMethodType? { _asInlineFragment() }
            public var asProductType: AsProductType? { _asInlineFragment() }
            public var asBranchType: AsBranchType? { _asInlineFragment() }

            /// AiChat.Output.Entity.AsPaymentMethodType
            ///
            /// Parent Type: `PaymentMethodType`
            public struct AsPaymentMethodType: LlegoAPI.InlineFragment {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              public typealias RootEntityType = AIChatQuery.Data.AiChat.Output.Entity
              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentMethodType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("id", String.self),
                .field("currency", String.self),
                .field("method", String.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                AIChatQuery.Data.AiChat.Output.Entity.self,
                AIChatQuery.Data.AiChat.Output.Entity.AsPaymentMethodType.self
              ] }

              /// Payment method ID
              public var id: String { __data["id"] }
              /// Currency (e.g., CUP, USD)
              public var currency: String { __data["currency"] }
              /// Payment method (e.g., tarjeta, efectivo, transferencia)
              public var method: String { __data["method"] }
            }

            /// AiChat.Output.Entity.AsProductType
            ///
            /// Parent Type: `ProductType`
            public struct AsProductType: LlegoAPI.InlineFragment {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              public typealias RootEntityType = AIChatQuery.Data.AiChat.Output.Entity
              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("id", String.self),
                .field("name", String.self),
                .field("description", String.self),
                .field("price", Double.self),
                .field("currency", String.self),
                .field("image", String.self),
                .field("availability", Bool.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                AIChatQuery.Data.AiChat.Output.Entity.self,
                AIChatQuery.Data.AiChat.Output.Entity.AsProductType.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var description: String { __data["description"] }
              public var price: Double { __data["price"] }
              public var currency: String { __data["currency"] }
              public var image: String { __data["image"] }
              public var availability: Bool { __data["availability"] }
            }

            /// AiChat.Output.Entity.AsBranchType
            ///
            /// Parent Type: `BranchType`
            public struct AsBranchType: LlegoAPI.InlineFragment {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              public typealias RootEntityType = AIChatQuery.Data.AiChat.Output.Entity
              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("id", String.self),
                .field("name", String.self),
                .field("address", String?.self),
                .field("phone", String.self),
                .field("status", String.self),
                .field("coordinates", Coordinates.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                AIChatQuery.Data.AiChat.Output.Entity.self,
                AIChatQuery.Data.AiChat.Output.Entity.AsBranchType.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var address: String? { __data["address"] }
              public var phone: String { __data["phone"] }
              public var status: String { __data["status"] }
              public var coordinates: Coordinates { __data["coordinates"] }

              /// AiChat.Output.Entity.AsBranchType.Coordinates
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
                  AIChatQuery.Data.AiChat.Output.Entity.AsBranchType.Coordinates.self
                ] }

                public var type: String { __data["type"] }
                public var coordinates: [Double] { __data["coordinates"] }
              }
            }
          }
        }
      }
    }
  }

}