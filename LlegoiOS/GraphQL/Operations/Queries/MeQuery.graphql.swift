// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct MeQuery: GraphQLQuery {
    public static let operationName: String = "Me"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me($jwt: String!) { me(jwt: $jwt) { __typename id name email username phone role createdAt providerUserId avatar avatarUrl savedAddresses { __typename id label street city reference addressType buildingName floor apartment deliveryInstructions latitude longitude } defaultAddressId scheduledDeletionAt } }"#
      ))

    public var jwt: String

    public init(jwt: String) {
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { ["jwt": jwt] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me?.self, arguments: ["jwt": .variable("jwt")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      /// Usuario actual desde JWT
      public var me: Me? { __data["me"] }

      /// Me
      ///
      /// Parent Type: `UserType`
      public struct Me: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("email", String.self),
          .field("username", String.self),
          .field("phone", String?.self),
          .field("role", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("providerUserId", String?.self),
          .field("avatar", String?.self),
          .field("avatarUrl", String?.self),
          .field("savedAddresses", [SavedAddress].self),
          .field("defaultAddressId", String?.self),
          .field("scheduledDeletionAt", LlegoAPI.DateTime?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var email: String { __data["email"] }
        public var username: String { __data["username"] }
        public var phone: String? { __data["phone"] }
        public var role: String { __data["role"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        public var providerUserId: String? { __data["providerUserId"] }
        public var avatar: String? { __data["avatar"] }
        /// URL firmada del avatar del usuario
        public var avatarUrl: String? { __data["avatarUrl"] }
        public var savedAddresses: [SavedAddress] { __data["savedAddresses"] }
        public var defaultAddressId: String? { __data["defaultAddressId"] }
        public var scheduledDeletionAt: LlegoAPI.DateTime? { __data["scheduledDeletionAt"] }

        /// Me.SavedAddress
        ///
        /// Parent Type: `SavedAddressType`
        public struct SavedAddress: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.SavedAddressType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("label", String.self),
            .field("street", String.self),
            .field("city", String?.self),
            .field("reference", String?.self),
            .field("addressType", String.self),
            .field("buildingName", String?.self),
            .field("floor", String?.self),
            .field("apartment", String?.self),
            .field("deliveryInstructions", String?.self),
            .field("latitude", Double.self),
            .field("longitude", Double.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MeQuery.Data.Me.SavedAddress.self
          ] }

          public var id: String { __data["id"] }
          public var label: String { __data["label"] }
          public var street: String { __data["street"] }
          public var city: String? { __data["city"] }
          public var reference: String? { __data["reference"] }
          public var addressType: String { __data["addressType"] }
          public var buildingName: String? { __data["buildingName"] }
          public var floor: String? { __data["floor"] }
          public var apartment: String? { __data["apartment"] }
          public var deliveryInstructions: String? { __data["deliveryInstructions"] }
          public var latitude: Double { __data["latitude"] }
          public var longitude: Double { __data["longitude"] }
        }
      }
    }
  }

}