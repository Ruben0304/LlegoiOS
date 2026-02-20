// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct RemoveSavedAddressMutation: GraphQLMutation {
    public static let operationName: String = "RemoveSavedAddress"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RemoveSavedAddress($addressId: String!, $jwt: String!) { removeSavedAddress(addressId: $addressId, jwt: $jwt) { __typename id savedAddresses { __typename id label street city reference addressType buildingName floor apartment deliveryInstructions latitude longitude } defaultAddressId } }"#
      ))

    public var addressId: String
    public var jwt: String

    public init(
      addressId: String,
      jwt: String
    ) {
      self.addressId = addressId
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "addressId": addressId,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("removeSavedAddress", RemoveSavedAddress.self, arguments: [
          "addressId": .variable("addressId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RemoveSavedAddressMutation.Data.self
      ] }

      /// Eliminar una dirección guardada del perfil
      public var removeSavedAddress: RemoveSavedAddress { __data["removeSavedAddress"] }

      /// RemoveSavedAddress
      ///
      /// Parent Type: `UserType`
      public struct RemoveSavedAddress: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("savedAddresses", [SavedAddress].self),
          .field("defaultAddressId", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RemoveSavedAddressMutation.Data.RemoveSavedAddress.self
        ] }

        public var id: String { __data["id"] }
        public var savedAddresses: [SavedAddress] { __data["savedAddresses"] }
        public var defaultAddressId: String? { __data["defaultAddressId"] }

        /// RemoveSavedAddress.SavedAddress
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
            RemoveSavedAddressMutation.Data.RemoveSavedAddress.SavedAddress.self
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