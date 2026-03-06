// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SyncImagesQuery: GraphQLQuery {
    public static let operationName: String = "SyncImages"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SyncImages($entityType: String, $entityIds: [String!], $qualities: [ImageQuality!]) { syncImages( entityType: $entityType entityIds: $entityIds qualities: $qualities ) { __typename entityId entityType imagePath urls { __typename baja original } } }"#
      ))

    public var entityType: GraphQLNullable<String>
    public var entityIds: GraphQLNullable<[String]>
    public var qualities: GraphQLNullable<[GraphQLEnum<ImageQuality>]>

    public init(
      entityType: GraphQLNullable<String>,
      entityIds: GraphQLNullable<[String]>,
      qualities: GraphQLNullable<[GraphQLEnum<ImageQuality>]>
    ) {
      self.entityType = entityType
      self.entityIds = entityIds
      self.qualities = qualities
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "entityType": entityType,
      "entityIds": entityIds,
      "qualities": qualities
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("syncImages", [SyncImage].self, arguments: [
          "entityType": .variable("entityType"),
          "entityIds": .variable("entityIds"),
          "qualities": .variable("qualities")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SyncImagesQuery.Data.self
      ] }

      /// Sincronizar imágenes con URLs para diferentes calidades (100x100, 500x500, 1000x1000, original)
      public var syncImages: [SyncImage] { __data["syncImages"] }

      /// SyncImage
      ///
      /// Parent Type: `ImageSyncType`
      public struct SyncImage: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ImageSyncType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("entityId", String.self),
          .field("entityType", String.self),
          .field("imagePath", String.self),
          .field("urls", Urls.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SyncImagesQuery.Data.SyncImage.self
        ] }

        public var entityId: String { __data["entityId"] }
        public var entityType: String { __data["entityType"] }
        public var imagePath: String { __data["imagePath"] }
        public var urls: Urls { __data["urls"] }

        /// SyncImage.Urls
        ///
        /// Parent Type: `ImageUrlType`
        public struct Urls: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ImageUrlType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("baja", String?.self),
            .field("original", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SyncImagesQuery.Data.SyncImage.Urls.self
          ] }

          public var baja: String? { __data["baja"] }
          public var original: String? { __data["original"] }
        }
      }
    }
  }

}