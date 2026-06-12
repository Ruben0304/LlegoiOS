// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetDiscountedServiceFeeRateQuery: GraphQLQuery {
    public static let operationName: String = "GetDiscountedServiceFeeRate"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetDiscountedServiceFeeRate { getDiscountedServiceFeeRate }"#
      ))

    public init() {}

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("getDiscountedServiceFeeRate", Double.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetDiscountedServiceFeeRateQuery.Data.self
      ] }

      /// Tasa de cargo de servicio reducida tras ver videos promocionales (fracción, ej: 0.05 = 5%)
      public var getDiscountedServiceFeeRate: Double { __data["getDiscountedServiceFeeRate"] }
    }
  }

}