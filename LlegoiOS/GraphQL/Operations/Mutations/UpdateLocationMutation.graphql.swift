// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct UpdateLocationMutation: GraphQLMutation {
    public static let operationName: String = "UpdateLocation"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateLocation($input: UpdateLocationInput!, $jwt: String) { updateLocation(input: $input, jwt: $jwt) { __typename id name email } }"#
      ))

    public var input: UpdateLocationInput
    public var jwt: GraphQLNullable<String>

    public init(
      input: UpdateLocationInput,
      jwt: GraphQLNullable<String>
    ) {
      self.input = input
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "input": input,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("updateLocation", UpdateLocation.self, arguments: [
          "input": .variable("input"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateLocationMutation.Data.self
      ] }

      /// Actualizar ubicación del usuario
      public var updateLocation: UpdateLocation { __data["updateLocation"] }

      /// UpdateLocation
      ///
      /// Parent Type: `UserType`
      public struct UpdateLocation: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.UserType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("name", String.self),
          .field("email", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateLocationMutation.Data.UpdateLocation.self
        ] }

        public var id: String { __data["id"] }
        public var name: String { __data["name"] }
        public var email: String { __data["email"] }
      }
    }
  }

}