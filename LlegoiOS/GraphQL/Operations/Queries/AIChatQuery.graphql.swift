// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct AIChatQuery: GraphQLQuery {
    public static let operationName: String = "AIChat"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query AIChat($message: String!, $deviceId: String, $jwt: String) { aiChat(input: { message: $message, deviceId: $deviceId }, jwt: $jwt) { __typename success { __typename responseType aiText suggestedProducts { __typename product { __typename id name description price currency imageUrl availability } reason branchName branchAvatarUrl branchAddress branchPhone } suggestedBranches { __typename branch { __typename id name address phone status tipos avatarUrl coordinates { __typename type coordinates } } reason } confidence } error { __typename code message quota { __typename source limit used remaining } retryAfter maxWords wordsCount } } }"#
      ))

    public var message: String
    public var deviceId: GraphQLNullable<String>
    public var jwt: GraphQLNullable<String>

    public init(
      message: String,
      deviceId: GraphQLNullable<String>,
      jwt: GraphQLNullable<String>
    ) {
      self.message = message
      self.deviceId = deviceId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "message": message,
      "deviceId": deviceId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("aiChat", AiChat.self, arguments: [
          "input": [
            "message": .variable("message"),
            "deviceId": .variable("deviceId")
          ],
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AIChatQuery.Data.self
      ] }

      /// Send a message to the AI assistant and get a response with RAG. Use stream=true for GraphQL subscription streaming.
      public var aiChat: AiChat { __data["aiChat"] }

      /// AiChat
      ///
      /// Parent Type: `AiChatResult`
      public struct AiChat: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiChatResult }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Success?.self),
          .field("error", Error_SelectionSet?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AIChatQuery.Data.AiChat.self
        ] }

        /// Successful response data
        public var success: Success? { __data["success"] }
        /// Error information if request failed
        public var error: Error_SelectionSet? { __data["error"] }

        /// AiChat.Success
        ///
        /// Parent Type: `AiAssistantResponseType`
        public struct Success: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiAssistantResponseType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("responseType", String.self),
            .field("aiText", String.self),
            .field("suggestedProducts", [SuggestedProduct].self),
            .field("suggestedBranches", [SuggestedBranch].self),
            .field("confidence", Double.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AIChatQuery.Data.AiChat.Success.self
          ] }

          /// Type of response: search_products, search_branches, create_draft_order, request_details, general_response
          public var responseType: String { __data["responseType"] }
          /// Natural language response from AI
          public var aiText: String { __data["aiText"] }
          /// Products suggested by AI
          public var suggestedProducts: [SuggestedProduct] { __data["suggestedProducts"] }
          /// Branches suggested by AI
          public var suggestedBranches: [SuggestedBranch] { __data["suggestedBranches"] }
          /// AI confidence score (0.0 to 1.0)
          public var confidence: Double { __data["confidence"] }

          /// AiChat.Success.SuggestedProduct
          ///
          /// Parent Type: `ProductSuggestionType`
          public struct SuggestedProduct: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductSuggestionType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("product", Product.self),
              .field("reason", String.self),
              .field("branchName", String?.self),
              .field("branchAvatarUrl", String?.self),
              .field("branchAddress", String?.self),
              .field("branchPhone", String?.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AIChatQuery.Data.AiChat.Success.SuggestedProduct.self
            ] }

            /// The suggested product
            public var product: Product { __data["product"] }
            /// Why this product was suggested
            public var reason: String { __data["reason"] }
            /// Branch name where product is sold
            public var branchName: String? { __data["branchName"] }
            /// Presigned URL for the branch avatar
            public var branchAvatarUrl: String? { __data["branchAvatarUrl"] }
            /// Branch address
            public var branchAddress: String? { __data["branchAddress"] }
            /// Branch phone number
            public var branchPhone: String? { __data["branchPhone"] }

            /// AiChat.Success.SuggestedProduct.Product
            ///
            /// Parent Type: `ProductType`
            public struct Product: LlegoAPI.SelectionSet {
              @_spi(Unsafe) public let __data: DataDict
              @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

              @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
              @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
                .field("__typename", String.self),
                .field("id", String.self),
                .field("name", String.self),
                .field("description", String.self),
                .field("price", Double.self),
                .field("currency", String.self),
                .field("imageUrl", String.self),
                .field("availability", Bool.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                AIChatQuery.Data.AiChat.Success.SuggestedProduct.Product.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var description: String { __data["description"] }
              public var price: Double { __data["price"] }
              public var currency: String { __data["currency"] }
              /// Presigned URL for the product image
              public var imageUrl: String { __data["imageUrl"] }
              public var availability: Bool { __data["availability"] }
            }
          }

          /// AiChat.Success.SuggestedBranch
          ///
          /// Parent Type: `BranchSuggestionType`
          public struct SuggestedBranch: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchSuggestionType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("branch", Branch.self),
              .field("reason", String.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AIChatQuery.Data.AiChat.Success.SuggestedBranch.self
            ] }

            /// The suggested branch
            public var branch: Branch { __data["branch"] }
            /// Why this branch was suggested
            public var reason: String { __data["reason"] }

            /// AiChat.Success.SuggestedBranch.Branch
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
                .field("address", String?.self),
                .field("phone", String.self),
                .field("status", String?.self),
                .field("tipos", [GraphQLEnum<LlegoAPI.BranchTipo>].self),
                .field("avatarUrl", String?.self),
                .field("coordinates", Coordinates.self),
              ] }
              @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
                AIChatQuery.Data.AiChat.Success.SuggestedBranch.Branch.self
              ] }

              public var id: String { __data["id"] }
              public var name: String { __data["name"] }
              public var address: String? { __data["address"] }
              public var phone: String { __data["phone"] }
              public var status: String? { __data["status"] }
              public var tipos: [GraphQLEnum<LlegoAPI.BranchTipo>] { __data["tipos"] }
              /// Presigned URL for the branch avatar (inherits from business if not set)
              public var avatarUrl: String? { __data["avatarUrl"] }
              public var coordinates: Coordinates { __data["coordinates"] }

              /// AiChat.Success.SuggestedBranch.Branch.Coordinates
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
                  AIChatQuery.Data.AiChat.Success.SuggestedBranch.Branch.Coordinates.self
                ] }

                public var type: String { __data["type"] }
                public var coordinates: [Double] { __data["coordinates"] }
              }
            }
          }
        }

        /// AiChat.Error_SelectionSet
        ///
        /// Parent Type: `AiChatError`
        public struct Error_SelectionSet: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiChatError }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("code", GraphQLEnum<LlegoAPI.AiChatErrorCode>.self),
            .field("message", String.self),
            .field("quota", Quota?.self),
            .field("retryAfter", Int?.self),
            .field("maxWords", Int?.self),
            .field("wordsCount", Int?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AIChatQuery.Data.AiChat.Error_SelectionSet.self
          ] }

          /// Error code
          public var code: GraphQLEnum<LlegoAPI.AiChatErrorCode> { __data["code"] }
          /// Human-readable error message
          public var message: String { __data["message"] }
          /// Quota information (if applicable)
          public var quota: Quota? { __data["quota"] }
          /// Seconds until retry is allowed (if applicable)
          public var retryAfter: Int? { __data["retryAfter"] }
          /// Maximum allowed words (for MESSAGE_TOO_LONG)
          public var maxWords: Int? { __data["maxWords"] }
          /// Actual word count (for MESSAGE_TOO_LONG)
          public var wordsCount: Int? { __data["wordsCount"] }

          /// AiChat.Error_SelectionSet.Quota
          ///
          /// Parent Type: `AiChatQuotaInfo`
          public struct Quota: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AiChatQuotaInfo }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("source", String.self),
              .field("limit", Int.self),
              .field("used", Int.self),
              .field("remaining", Int.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              AIChatQuery.Data.AiChat.Error_SelectionSet.Quota.self
            ] }

            /// Quota source identifier
            public var source: String { __data["source"] }
            /// Total quota limit
            public var limit: Int { __data["limit"] }
            /// Amount used
            public var used: Int { __data["used"] }
            /// Amount remaining
            public var remaining: Int { __data["remaining"] }
          }
        }
      }
    }
  }

}