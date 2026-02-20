// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct SetDefaultAddressMutation: GraphQLMutation {
    public static let operationName: String = "SetDefaultAddress"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SetDefaultAddress($addressId: String!, $jwt: String!) { setDefaultAddress(addressId: $addressId, jwt: $jwt) { __typename id defaultAddressId } }"#
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
        .field("setDefaultAddress", SetDefaultAddress.self, arguments: [
          "addressId": .variable("addressId"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SetDefaultAddressMutation.Data.self
      ] }

      /// Establecer la dirección de entrega por defecto
      public var setDefaultAddress: SetDefaultAddress { __data["setDefaultAddress"] }

      /// SetDefaultAddress
      ///
      /// Parent Type: `UserType`
      public struct SetDefaultAddress: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("defaultAddressId", String?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SetDefaultAddressMutation.Data.SetDefaultAddress.self
        ] }

        public var id: String { __data["id"] }
        public var defaultAddressId: String? { __data["defaultAddressId"] }
      }
    }
  }

}