// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetActivePromotionalVideosQuery: GraphQLQuery {
    public static let operationName: String = "GetActivePromotionalVideos"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetActivePromotionalVideos { activePromotionalVideos { __typename id title description videoUrl videoUrlSigned duration appTarget thumbnailUrl thumbnailUrlSigned branchId branchName branchAvatarUrl order tags } }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("activePromotionalVideos", [ActivePromotionalVideo].self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetActivePromotionalVideosQuery.Data.self
      ] }

      /// Get active promotional videos only
      public var activePromotionalVideos: [ActivePromotionalVideo] { __data["activePromotionalVideos"] }

      /// ActivePromotionalVideo
      ///
      /// Parent Type: `PromotionalVideoType`
      public struct ActivePromotionalVideo: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PromotionalVideoType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("title", String.self),
          .field("description", String.self),
          .field("videoUrl", String.self),
          .field("videoUrlSigned", String.self),
          .field("duration", Int.self),
          .field("appTarget", GraphQLEnum<LlegoAPI.AppTarget>.self),
          .field("thumbnailUrl", String?.self),
          .field("thumbnailUrlSigned", String?.self),
          .field("branchId", String?.self),
          .field("branchName", String?.self),
          .field("branchAvatarUrl", String?.self),
          .field("order", Int.self),
          .field("tags", [String].self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetActivePromotionalVideosQuery.Data.ActivePromotionalVideo.self
        ] }

        public var id: String { __data["id"] }
        public var title: String { __data["title"] }
        public var description: String { __data["description"] }
        public var videoUrl: String { __data["videoUrl"] }
        /// Presigned URL for the promo video
        public var videoUrlSigned: String { __data["videoUrlSigned"] }
        public var duration: Int { __data["duration"] }
        public var appTarget: GraphQLEnum<LlegoAPI.AppTarget> { __data["appTarget"] }
        public var thumbnailUrl: String? { __data["thumbnailUrl"] }
        /// Presigned URL for the promo thumbnail
        public var thumbnailUrlSigned: String? { __data["thumbnailUrlSigned"] }
        public var branchId: String? { __data["branchId"] }
        /// Name of the branch that uploaded the promo (optional)
        public var branchName: String? { __data["branchName"] }
        /// Presigned avatar URL of the branch that uploaded the promo (optional)
        public var branchAvatarUrl: String? { __data["branchAvatarUrl"] }
        public var order: Int { __data["order"] }
        public var tags: [String] { __data["tags"] }
      }
    }
  }

}