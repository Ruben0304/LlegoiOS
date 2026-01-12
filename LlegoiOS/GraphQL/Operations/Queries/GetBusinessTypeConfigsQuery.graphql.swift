// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetBusinessTypeConfigsQuery: GraphQLQuery {
    public static let operationName: String = "GetBusinessTypeConfigs"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetBusinessTypeConfigs($lastSyncAt: DateTime) { businessTypeConfigs(lastSyncAt: $lastSyncAt) { __typename id key name description icon model3dFileName model3dUrl model3dVersion gradient { __typename darkColor mediumColor lightColor veryLightColor overlayColor } camera { __typename positionX positionY positionZ eulerX eulerY eulerZ } glowColor features { __typename icon title subtitle sortOrder } sortOrder isActive createdAt updatedAt } }"#
      ))

    public var lastSyncAt: GraphQLNullable<DateTime>

    public init(lastSyncAt: GraphQLNullable<DateTime>) {
      self.lastSyncAt = lastSyncAt
    }

    @_spi(Unsafe) public var __variables: Variables? { ["lastSyncAt": lastSyncAt] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("businessTypeConfigs", [BusinessTypeConfig].self, arguments: ["lastSyncAt": .variable("lastSyncAt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetBusinessTypeConfigsQuery.Data.self
      ] }

      /// Get business type configurations (supports incremental sync)
      public var businessTypeConfigs: [BusinessTypeConfig] { __data["businessTypeConfigs"] }

      /// BusinessTypeConfig
      ///
      /// Parent Type: `BusinessTypeConfigType`
      public struct BusinessTypeConfig: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessTypeConfigType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("key", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("icon", String.self),
          .field("model3dFileName", String.self),
          .field("model3dUrl", String?.self),
          .field("model3dVersion", Int.self),
          .field("gradient", Gradient.self),
          .field("camera", Camera.self),
          .field("glowColor", String.self),
          .field("features", [Feature].self),
          .field("sortOrder", Int.self),
          .field("isActive", Bool.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("updatedAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetBusinessTypeConfigsQuery.Data.BusinessTypeConfig.self
        ] }

        public var id: String { __data["id"] }
        public var key: String { __data["key"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var icon: String { __data["icon"] }
        public var model3dFileName: String { __data["model3dFileName"] }
        public var model3dUrl: String? { __data["model3dUrl"] }
        public var model3dVersion: Int { __data["model3dVersion"] }
        public var gradient: Gradient { __data["gradient"] }
        public var camera: Camera { __data["camera"] }
        public var glowColor: String { __data["glowColor"] }
        public var features: [Feature] { __data["features"] }
        public var sortOrder: Int { __data["sortOrder"] }
        public var isActive: Bool { __data["isActive"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var updatedAt: LlegoAPI.DateTime { __data["updatedAt"] }

        /// BusinessTypeConfig.Gradient
        ///
        /// Parent Type: `GradientConfigType`
        public struct Gradient: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.GradientConfigType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("darkColor", String.self),
            .field("mediumColor", String.self),
            .field("lightColor", String.self),
            .field("veryLightColor", String.self),
            .field("overlayColor", String.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBusinessTypeConfigsQuery.Data.BusinessTypeConfig.Gradient.self
          ] }

          public var darkColor: String { __data["darkColor"] }
          public var mediumColor: String { __data["mediumColor"] }
          public var lightColor: String { __data["lightColor"] }
          public var veryLightColor: String { __data["veryLightColor"] }
          public var overlayColor: String { __data["overlayColor"] }
        }

        /// BusinessTypeConfig.Camera
        ///
        /// Parent Type: `CameraConfigType`
        public struct Camera: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.CameraConfigType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("positionX", Double.self),
            .field("positionY", Double.self),
            .field("positionZ", Double.self),
            .field("eulerX", Double?.self),
            .field("eulerY", Double?.self),
            .field("eulerZ", Double?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBusinessTypeConfigsQuery.Data.BusinessTypeConfig.Camera.self
          ] }

          public var positionX: Double { __data["positionX"] }
          public var positionY: Double { __data["positionY"] }
          public var positionZ: Double { __data["positionZ"] }
          public var eulerX: Double? { __data["eulerX"] }
          public var eulerY: Double? { __data["eulerY"] }
          public var eulerZ: Double? { __data["eulerZ"] }
        }

        /// BusinessTypeConfig.Feature
        ///
        /// Parent Type: `FeatureType`
        public struct Feature: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.FeatureType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("icon", String.self),
            .field("title", String.self),
            .field("subtitle", String.self),
            .field("sortOrder", Int.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetBusinessTypeConfigsQuery.Data.BusinessTypeConfig.Feature.self
          ] }

          public var icon: String { __data["icon"] }
          public var title: String { __data["title"] }
          public var subtitle: String { __data["subtitle"] }
          public var sortOrder: Int { __data["sortOrder"] }
        }
      }
    }
  }

}