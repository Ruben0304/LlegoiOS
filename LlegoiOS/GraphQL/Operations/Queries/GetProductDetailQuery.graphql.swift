// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

public extension LlegoAPI {
  struct GetProductDetailQuery: GraphQLQuery {
    public static let operationName: String = "GetProductDetail"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetProductDetail($id: String!, $jwt: String) { product(id: $id, jwt: $jwt) { __typename id branchId name description weight price currency convertedPrice convertedCurrency exchangeRate imageUrl availability categoryId variantListIds variantLists { __typename id name description options { __typename id name priceAdjustment } } createdAt branch { __typename id name avatarUrl } business { __typename id name avatarUrl } } }"#
      ))

    public var id: String
    public var jwt: GraphQLNullable<String>

    public init(
      id: String,
      jwt: GraphQLNullable<String>
    ) {
      self.id = id
      self.jwt = jwt
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "jwt": jwt
    ] }

    public struct Data: LlegoAPI.SelectionSet {
      @_spi(Unsafe) public let __data: DataDict
      @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

      @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.Query }
      @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
        .field("product", Product?.self, arguments: [
          "id": .variable("id"),
          "jwt": .variable("jwt")
        ]),
      ] }
      @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetProductDetailQuery.Data.self
      ] }

      /// Obtener producto por ID
      public var product: Product? { __data["product"] }

      /// Product
      ///
      /// Parent Type: `ProductType`
      public struct Product: LlegoAPI.SelectionSet {
        @_spi(Unsafe) public let __data: DataDict
        @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

        @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.ProductType }
        @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", String.self),
          .field("branchId", String.self),
          .field("name", String.self),
          .field("description", String.self),
          .field("weight", String.self),
          .field("price", Double.self),
          .field("currency", String.self),
          .field("convertedPrice", Double?.self),
          .field("convertedCurrency", String?.self),
          .field("exchangeRate", Int?.self),
          .field("imageUrl", String.self),
          .field("availability", Bool.self),
          .field("categoryId", String?.self),
          .field("variantListIds", [String].self),
          .field("variantLists", [VariantList].self),
          .field("createdAt", LlegoAPI.DateTime.self),
          .field("branch", Branch?.self),
          .field("business", Business?.self),
        ] }
        @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetProductDetailQuery.Data.Product.self
        ] }

        public var id: String { __data["id"] }
        public var branchId: String { __data["branchId"] }
        public var name: String { __data["name"] }
        public var description: String { __data["description"] }
        public var weight: String { __data["weight"] }
        public var price: Double { __data["price"] }
        public var currency: String { __data["currency"] }
        /// Precio convertido a la otra moneda (si la sucursal acepta ambas)
        public var convertedPrice: Double? { __data["convertedPrice"] }
        /// Moneda del precio convertido
        public var convertedCurrency: String? { __data["convertedCurrency"] }
        /// Tasa de cambio de la sucursal (si acepta ambas monedas)
        public var exchangeRate: Int? { __data["exchangeRate"] }
        /// Presigned URL for the product image
        public var imageUrl: String { __data["imageUrl"] }
        public var availability: Bool { __data["availability"] }
        public var categoryId: String? { __data["categoryId"] }
        public var variantListIds: [String] { __data["variantListIds"] }
        /// Variant lists assigned to this product
        public var variantLists: [VariantList] { __data["variantLists"] }
        public var createdAt: LlegoAPI.DateTime { __data["createdAt"] }
        /// Branch associated with this product
        public var branch: Branch? { __data["branch"] }
        /// Business associated with this product (through branch)
        public var business: Business? { __data["business"] }

        /// Product.VariantList
        ///
        /// Parent Type: `VariantListType`
        public struct VariantList: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.VariantListType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("description", String?.self),
            .field("options", [Option].self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductDetailQuery.Data.Product.VariantList.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          public var description: String? { __data["description"] }
          public var options: [Option] { __data["options"] }

          /// Product.VariantList.Option
          ///
          /// Parent Type: `VariantOptionType`
          public struct Option: LlegoAPI.SelectionSet {
            @_spi(Unsafe) public let __data: DataDict
            @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

            @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.VariantOptionType }
            @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", String.self),
              .field("name", String.self),
              .field("priceAdjustment", Double.self),
            ] }
            @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetProductDetailQuery.Data.Product.VariantList.Option.self
            ] }

            public var id: String { __data["id"] }
            public var name: String { __data["name"] }
            public var priceAdjustment: Double { __data["priceAdjustment"] }
          }
        }

        /// Product.Branch
        ///
        /// Parent Type: `BranchType`
        public struct Branch: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BranchType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("avatarUrl", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductDetailQuery.Data.Product.Branch.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the branch avatar (inherits from business if not set)
          public var avatarUrl: String? { __data["avatarUrl"] }
        }

        /// Product.Business
        ///
        /// Parent Type: `BusinessType`
        public struct Business: LlegoAPI.SelectionSet {
          @_spi(Unsafe) public let __data: DataDict
          @_spi(Unsafe) public init(_dataDict: DataDict) { __data = _dataDict }

          @_spi(Execution) public static var __parentType: any ApolloAPI.ParentType { LlegoAPI.Objects.BusinessType }
          @_spi(Execution) public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", String.self),
            .field("name", String.self),
            .field("avatarUrl", String?.self),
          ] }
          @_spi(Execution) public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetProductDetailQuery.Data.Product.Business.self
          ] }

          public var id: String { __data["id"] }
          public var name: String { __data["name"] }
          /// Presigned URL for the business avatar
          public var avatarUrl: String? { __data["avatarUrl"] }
        }
      }
    }
  }

}