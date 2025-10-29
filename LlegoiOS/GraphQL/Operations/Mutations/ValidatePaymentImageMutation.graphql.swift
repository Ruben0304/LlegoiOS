// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct ValidatePaymentImageMutation: GraphQLMutation {
    public static let operationName: String = "ValidatePaymentImage"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ValidatePaymentImage($file: Upload!) { validatePaymentImage(file: $file) { __typename id quienEnvio banco fecha esMensajeBanco cantidadTransferida numeroTransferencia primeros4Tarjeta ultimos4Tarjeta createdAt } }"#
      ))

    public var file: Upload

    public init(file: Upload) {
      self.file = file
    }

    @_spi(Unsafe) public var __variables: Variables? { ["file": file] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Mutation }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("validatePaymentImage", ValidatePaymentImage.self, arguments: ["file": .variable("file")]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ValidatePaymentImageMutation.Data.self
      ] }

      /// Validar una imagen de transferencia bancaria usando Gemini OCR
      public var validatePaymentImage: ValidatePaymentImage { __data["validatePaymentImage"] }

      /// ValidatePaymentImage
      ///
      /// Parent Type: `PaymentType`
      public struct ValidatePaymentImage: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.PaymentType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("quienEnvio", String.self),
          .field("banco", String.self),
          .field("fecha", LlegoAPI.DateTime.self),
          .field("esMensajeBanco", Bool.self),
          .field("cantidadTransferida", Double.self),
          .field("numeroTransferencia", String.self),
          .field("primeros4Tarjeta", String.self),
          .field("ultimos4Tarjeta", String.self),
          .field("createdAt", LlegoAPI.DateTime.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ValidatePaymentImageMutation.Data.ValidatePaymentImage.self
        ] }

        public var id: String { __data["id"] }
        public var quienEnvio: String { __data["quienEnvio"] }
        public var banco: String { __data["banco"] }
        public var fecha: LlegoAPI.DateTime { __data["fecha"] }
        public var esMensajeBanco: Bool { __data["esMensajeBanco"] }
        public var cantidadTransferida: Double { __data["cantidadTransferida"] }
        public var numeroTransferencia: String { __data["numeroTransferencia"] }
        public var primeros4Tarjeta: String { __data["primeros4Tarjeta"] }
        public var ultimos4Tarjeta: String { __data["ultimos4Tarjeta"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}