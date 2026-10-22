// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct EstimateDeliveryFeeQuery: GraphQLQuery {
    public static let operationName: String = "EstimateDeliveryFee"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query EstimateDeliveryFee($branchId: String!, $jwt: String!, $latitude: Float, $longitude: Float) { estimateDeliveryFee( branchId: $branchId jwt: $jwt latitude: $latitude longitude: $longitude ) { __typename deliveryFee currency distanceKm zoneName branchId branchName } }"#
      ))

    public var branchId: String
    public var jwt: String
    public var latitude: GraphQLNullable<Double>
    public var longitude: GraphQLNullable<Double>

    public init(
      branchId: String,
      jwt: String,
      latitude: GraphQLNullable<Double>,
      longitude: GraphQLNullable<Double>
    ) {
      self.branchId = branchId
      self.jwt = jwt
      self.latitude = latitude
      self.longitude = longitude
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "branchId": branchId,
      "jwt": jwt,
      "latitude": latitude,
      "longitude": longitude
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("estimateDeliveryFee", EstimateDeliveryFee.self, arguments: [
          "branchId": .variable("branchId"),
          "jwt": .variable("jwt"),
          "latitude": .variable("latitude"),
          "longitude": .variable("longitude")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        EstimateDeliveryFeeQuery.Data.self
      ] }

      /// Estimar precio de envío antes de crear el pedido. Usa la ubicación guardada del usuario autenticado.
      public var estimateDeliveryFee: EstimateDeliveryFee { __data["estimateDeliveryFee"] }

      /// EstimateDeliveryFee
      ///
      /// Parent Type: `DeliveryFeeEstimateType`
      public struct EstimateDeliveryFee: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.DeliveryFeeEstimateType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("deliveryFee", Double.self),
          .field("currency", String.self),
          .field("distanceKm", Double.self),
          .field("zoneName", String?.self),
          .field("branchId", String.self),
          .field("branchName", String.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          EstimateDeliveryFeeQuery.Data.EstimateDeliveryFee.self
        ] }

        public var deliveryFee: Double { __data["deliveryFee"] }
        public var currency: String { __data["currency"] }
        public var distanceKm: Double { __data["distanceKm"] }
        public var zoneName: String? { __data["zoneName"] }
        public var branchId: String { __data["branchId"] }
        public var branchName: String { __data["branchName"] }
      }
    }
  }

}