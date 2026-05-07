// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetServiceFeeRateQuery: GraphQLQuery {
    public static let operationName: String = "GetServiceFeeRate"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetServiceFeeRate { getServiceFeeRate }"#
      ))

    public init() {}

    @_spi(Unsafe) public var __variables: Variables? { nil }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("getServiceFeeRate", Double.self),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetServiceFeeRateQuery.Data.self
      ] }

      /// Retorna la tasa de cargo de servicio configurada en el servidor (fracción, ej: 0.10 = 10%)
      public var getServiceFeeRate: Double { __data["getServiceFeeRate"] }
    }
  }

}
