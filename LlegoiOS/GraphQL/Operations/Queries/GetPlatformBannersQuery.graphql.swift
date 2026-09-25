// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetPlatformBannersQuery: GraphQLQuery {
    public static let operationName: String = "GetPlatformBanners"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetPlatformBanners { platformBanners(appTarget: "customer") { __typename id imagePath imageUrl title actionUrl branchId order } }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("platformBanners", [PlatformBanner].self, arguments: ["appTarget": "customer"]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetPlatformBannersQuery.Data.self
      ] }

      /// Banners promocionales activos para el feed (público)
      public var platformBanners: [PlatformBanner] { __data["platformBanners"] }

      /// PlatformBanner
      ///
      /// Parent Type: `PlatformBannerType`
      public struct PlatformBanner: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PlatformBannerType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("imagePath", String.self),
          .field("imageUrl", String.self),
          .field("title", String?.self),
          .field("actionUrl", String?.self),
          .field("branchId", String?.self),
          .field("order", Int.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetPlatformBannersQuery.Data.PlatformBanner.self
        ] }

        public var id: String { __data["id"] }
        public var imagePath: String { __data["imagePath"] }
        /// URL pública (firmada, expira ~1h) de la imagen
        public var imageUrl: String { __data["imageUrl"] }
        public var title: String? { __data["title"] }
        /// URL a abrir al tocar: https://wa.me/<numero> si hay whatsapp, si no el link. Null si no hay acción externa.
        public var actionUrl: String? { __data["actionUrl"] }
        public var branchId: String? { __data["branchId"] }
        public var order: Int { __data["order"] }
      }
    }
  }

}