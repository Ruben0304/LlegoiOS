// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetAppConfigQuery: GraphQLQuery {
    public static let operationName: String = "GetAppConfig"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetAppConfig { appConfig { __typename id ios { __typename minVersion currentVersion storeUrl } maintenance { __typename enabled message } updateMessage changelog releaseDate } }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("appConfig", AppConfig?.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetAppConfigQuery.Data.self
      ] }

      /// Obtener configuración de la aplicación
      public var appConfig: AppConfig? { __data["appConfig"] }

      /// AppConfig
      ///
      /// Parent Type: `AppConfigType`
      public struct AppConfig: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.AppConfigType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("ios", Ios.self),
          .field("maintenance", Maintenance.self),
          .field("updateMessage", String?.self),
          .field("changelog", String?.self),
          .field("releaseDate", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetAppConfigQuery.Data.AppConfig.self
        ] }

        public var id: String { __data["id"] }
        public var ios: Ios { __data["ios"] }
        public var maintenance: Maintenance { __data["maintenance"] }
        /// Message to show when update is available
        public var updateMessage: String? { __data["updateMessage"] }
        /// Release notes
        public var changelog: String? { __data["changelog"] }
        /// Date of the latest release
        public var releaseDate: LlegoAPI.DateTime { __data["releaseDate"] }

        /// AppConfig.Ios
        ///
        /// Parent Type: `IosConfigType`
        public struct Ios: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.IosConfigType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("minVersion", String.self),
            .field("currentVersion", String.self),
            .field("storeUrl", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetAppConfigQuery.Data.AppConfig.Ios.self
          ] }

          /// Minimum version allowed
          public var minVersion: String { __data["minVersion"] }
          /// Latest available version
          public var currentVersion: String { __data["currentVersion"] }
          /// App Store URL
          public var storeUrl: String { __data["storeUrl"] }
        }

        /// AppConfig.Maintenance
        ///
        /// Parent Type: `MaintenanceConfigType`
        public struct Maintenance: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.MaintenanceConfigType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("enabled", Bool.self),
            .field("message", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetAppConfigQuery.Data.AppConfig.Maintenance.self
          ] }

          /// Whether maintenance mode is active
          public var enabled: Bool { __data["enabled"] }
          /// Message to display during maintenance
          public var message: String? { __data["message"] }
        }
      }
    }
  }

}